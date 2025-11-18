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
        .create_note("Meeting Notes".into(), "Discuss sync logic".into())
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

    // Start with same note on both
    let note = db_a.create_note("Base".into(), "Base".into()).unwrap();
    db_b.merge_changes(vec![note.clone()]).unwrap();

    // Device A updates note to v2
    let note_a_v2 = db_a.update_note(&note.id, "Version A".into(), "Content A".into()).unwrap();

    // Device B updates SAME note to v2 (Simulate race condition / concurrent offline edit)
    // Note: In our current simplified logic, we bump version locally.
    // If both bump to 2 independently, the last one to MERGE wins, or we need a tiebreaker.
    // Current implementation: if remote.version > local.version, overwrite.
    // If remote.version == local.version, we currently IGNORE remote (Local Wins Tie).

    let note_b_v2 = db_b.update_note(&note.id, "Version B".into(), "Content B".into()).unwrap();

    // Sync A -> B (B has v2, A sends v2)
    // B should ignore A's changes because B.version (2) is not < A.version (2).
    db_b.merge_changes(vec![note_a_v2.clone()]).unwrap();

    let current_b = db_b.get_all_notes().unwrap().pop().unwrap();
    assert_eq!(current_b.title, "Version B"); // Local B kept its own change

    // Sync B -> A (A has v2, B sends v2)
    // A should ignore B's changes
    db_a.merge_changes(vec![note_b_v2.clone()]).unwrap();

    let current_a = db_a.get_all_notes().unwrap().pop().unwrap();
    assert_eq!(current_a.title, "Version A"); // Local A kept its own change

    // Result: Divergence (Both stayed at v2 with different content).
    // Correction: Ideally, one creates v3.
    // This test documents current behavior. To fix this in Phase 2/3, we would need
    // vector clocks or Client IDs to break ties deterministically.
    // For "Hyper-lightweight", manual resolution or "Latest timestamp wins" is the next step.
    // For now, we assert the current behavior is stable/predictable.
}

#[test]
fn test_delete_propagation() {
    let db_a = create_device_db();
    let mut db_b = create_device_db();

    // Shared note
    let note = db_a.create_note("To Delete".into(), "Bye".into()).unwrap();
    db_b.merge_changes(vec![note.clone()]).unwrap();

    // Device A deletes
    db_a.delete_note(&note.id).unwrap();

    // Sync A -> B
    let changes = db_a.get_changes_since(1).unwrap();
    assert_eq!(changes[0].is_deleted, true);

    db_b.merge_changes(changes).unwrap();

    // Verify B sees it as deleted (empty list for get_all_notes)
    let notes_b = db_b.get_all_notes().unwrap();
    assert_eq!(notes_b.len(), 0);

    // But it exists in DB
    let raw_changes_b = db_b.get_changes_since(0).unwrap();
    let deleted_note = raw_changes_b.iter().find(|n| n.id == note.id).unwrap();
    assert!(deleted_note.is_deleted);
    assert_eq!(deleted_note.version, 2);
}
