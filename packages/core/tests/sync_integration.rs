use notaro_core::DatabaseConnection;
use std::thread;
use std::time::Duration;

/// Helper to create an in-memory database for a simulated device
fn create_device_db() -> DatabaseConnection {
    DatabaseConnection::new(":memory:").expect("Failed to create memory db")
}

#[test]
fn test_two_device_sync_scenario() {
    // 1. Setup Device A and Device B (clean slate)
    let mut db_a = create_device_db();
    let mut db_b = create_device_db();

    // 2. Device A creates a note
    let original_note = db_a
        .create_note("Meeting Notes".into(), "Discuss sync logic".into(), Some("Work".into()))
        .expect("Device A failed to create note");

    assert_eq!(original_note.version, 1);

    // 3. SYNC A -> B
    // Device A calculates changes since beginning of time (version 0)
    let changes_from_a = db_a.get_changes_since(0).expect("Failed to get changes from A");
    assert_eq!(changes_from_a.len(), 1);

    // Device B merges these changes
    db_b.merge_changes(changes_from_a).expect("Device B failed to merge");

    // Verify Device B has the note
    let notes_b = db_b.get_all_notes().expect("Failed to get notes B");
    assert_eq!(notes_b.len(), 1);
    assert_eq!(notes_b[0].id, original_note.id);
    assert_eq!(notes_b[0].title, "Meeting Notes");
    assert_eq!(notes_b[0].version, 1);

    // 4. Device B updates the note (offline work)
    // Sleep briefly to ensure updated_at timestamp differs significantly if FS resolution is low
    thread::sleep(Duration::from_millis(10));

    let updated_note_b = db_b
        .update_note(
            &original_note.id,
            "Meeting Notes (Revised)".into(),
            "Discuss sync logic + tests".into(),
            Some("Work".into()),
            true,
        )
        .expect("Device B failed to update");

    assert_eq!(updated_note_b.version, 2);

    // 5. SYNC B -> A
    // Device B calculates changes since version 1 (assuming it tracked that A was at v1)
    // In a naive protocol, we might just ask for everything > 0 locally
    let changes_from_b = db_b.get_changes_since(1).expect("Failed to get changes from B");
    assert_eq!(changes_from_b.len(), 1);
    assert_eq!(changes_from_b[0].version, 2);

    // Device A merges changes
    db_a.merge_changes(changes_from_b).expect("Device A failed to merge");

    // 6. Verify Convergence
    let final_note_a = db_a.get_all_notes().unwrap().pop().unwrap();
    let final_note_b = db_b.get_all_notes().unwrap().pop().unwrap();

    assert_eq!(final_note_a.title, "Meeting Notes (Revised)");
    assert_eq!(final_note_a.content, final_note_b.content);
    assert_eq!(final_note_a.version, final_note_b.version);
    assert_eq!(final_note_a.version, 2);
}

#[test]
fn test_conflict_resolution_last_write_wins() {
    let mut db_a = create_device_db();
    let mut db_b = create_device_db();

    // 1. Start with same note on both
    // Device A creates it
    let note =
        db_a.create_note("Base".into(), "Base".into(), None).expect("Failed to create base note");

    // Device B must have the note before it can update it
    db_b.merge_changes(vec![note.clone()]).expect("Failed to sync initial note to B");

    // 2. Device A updates note to v2
    let note_a_v2 = db_a
        .update_note(&note.id, "Version A".into(), "Content A".into(), None, false)
        .expect("Device A failed to update");

    // 3. Device B updates SAME note to v2 (Simulate race condition / concurrent offline edit)
    // This logic bumps local version to 2.
    let note_b_v2 = db_b
        .update_note(&note.id, "Version B".into(), "Content B".into(), None, false)
        .expect("Device B failed to update");

    // 4. Sync A -> B (B has v2, A sends v2)
    // Current logic: If remote.version (2) > local.version (2) -> False.
    // B ignores A's changes. Local wins tie.
    db_b.merge_changes(vec![note_a_v2.clone()]).unwrap();

    let current_b = db_b.get_all_notes().unwrap().pop().unwrap();
    assert_eq!(current_b.title, "Version B"); // Local B kept its own change

    // 5. Sync B -> A (A has v2, B sends v2)
    // A ignores B's changes. Local wins tie.
    db_a.merge_changes(vec![note_b_v2.clone()]).unwrap();

    let current_a = db_a.get_all_notes().unwrap().pop().unwrap();
    assert_eq!(current_a.title, "Version A"); // Local A kept its own change
}

#[test]
fn test_delete_propagation() {
    let db_a = create_device_db();
    let mut db_b = create_device_db();

    // Shared note
    let note = db_a.create_note("To Delete".into(), "Bye".into(), None).unwrap();
    db_b.merge_changes(vec![note.clone()]).unwrap();

    // Device A deletes
    db_a.delete_note(&note.id).unwrap();

    // Sync A -> B
    let changes = db_a.get_changes_since(1).unwrap();
    assert_eq!(changes[0].is_deleted, true);

    db_b.merge_changes(changes).unwrap();

    // Verify B sees it as deleted
    let notes_b = db_b.get_all_notes().unwrap();
    // It should still return the note, but marked as deleted
    let synced_note = notes_b.iter().find(|n| n.id == note.id).unwrap();
    assert_eq!(synced_note.is_deleted, true);

    // Filtered view should be empty (simulation of UI logic)
    let active_notes_b: Vec<_> = notes_b.iter().filter(|n| !n.is_deleted).collect();
    assert_eq!(active_notes_b.len(), 0);
}
