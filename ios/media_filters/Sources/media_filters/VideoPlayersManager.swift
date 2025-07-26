import Foundation

/// A thread-safe singleton manager responsible for creating, storing, and managing VideoPlayer instances.
///
/// This class provides centralized management of video players, ensuring proper lifecycle management
/// and thread safety when accessing player instances from multiple threads.
///
/// ## Usage Example
/// ```swift
/// // Create or get existing player
/// let player = VideoPlayersManager.create(playerId: 1)
///
/// // Retrieve existing player
/// if let existingPlayer = VideoPlayersManager.get(playerId: 1) {
///     // Use the player
/// }
///
/// // Remove player when done
/// VideoPlayersManager.remove(playerId: 1)
/// ```
public class VideoPlayersManager {
    /// Thread synchronization lock to ensure thread-safe access to the players dictionary
    private static let lock = NSLock()
    
    /// Internal storage for active video player instances, keyed by their unique identifiers
    private static var players: [Int: VideoPlayer] = [:]
    
    /// Returns the current number of active video players being managed
    ///
    /// This property is thread-safe and can be called from any queue.
    ///
    /// - Returns: The count of currently active video players
    public static var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return players.count
    }
    
    /// Creates a new VideoPlayer instance or returns an existing one with the specified ID.
    ///
    /// This method is thread-safe and will either create a new player if one doesn't exist
    /// with the given ID, or return the existing player instance.
    ///
    /// - Parameter playerId: A unique identifier for the video player. Must be unique across all players.
    /// - Returns: A VideoPlayer instance, either newly created or existing
    ///
    /// - Note: If a player with the same ID already exists, the existing instance is returned
    ///   without creating a new one, preventing memory leaks and duplicate players.
    public static func create(_ playerId: Int) -> VideoPlayer {
        lock.lock()
        defer { lock.unlock() }
        
        // Return existing player if already created
        if let existingPlayer = players[playerId] {
            return existingPlayer
        }
        
        // Create new player and store it
        let newPlayer = VideoPlayer(id: playerId)
        players[playerId] = newPlayer
        
        return newPlayer
    }
    
    /// Retrieves an existing VideoPlayer instance by its unique identifier.
    ///
    /// This method is thread-safe and will return nil if no player exists with the specified ID.
    ///
    /// - Parameter playerId: The unique identifier of the video player to retrieve
    /// - Returns: The VideoPlayer instance if found, nil otherwise
    ///
    /// - Note: Use this method when you need to access an existing player without creating a new one.
    ///   If you need to ensure a player exists, use `create(playerId:)` instead.
    public static func get(_ playerId: Int) -> VideoPlayer? {
        lock.lock()
        defer { lock.unlock() }
        
        return players[playerId]
    }
    
    /// Removes and properly releases a VideoPlayer instance with the specified ID.
    ///
    /// This method is thread-safe and will safely remove the player from the manager's storage.
    /// The player's `release()` method is called on the main actor to ensure proper cleanup
    /// of UI-related resources.
    ///
    /// - Parameter playerId: The unique identifier of the video player to remove
    ///
    /// - Note: If no player exists with the specified ID, this method has no effect.
    ///   The player's release method is called asynchronously on the main thread to ensure
    ///   proper cleanup of any UI components or main-thread-only resources.
    public static func remove(_ playerId: Int) {
        lock.lock()
        let playerToRemove = players.removeValue(forKey: playerId)
        lock.unlock()
        
        // Release player resources on main thread if player existed
        if let player = playerToRemove {
            Task { @MainActor in
                player.cleanup()
            }
        }
    }
    
    /// Removes and releases all currently managed VideoPlayer instances.
    ///
    /// This method is thread-safe and will clear all players from the manager's storage.
    /// Each player's `release()` method is called on the main actor to ensure proper cleanup.
    ///
    /// - Warning: This method will remove ALL active players. Use with caution, typically
    ///   during application shutdown or when you need to reset the entire player state.
    ///
    /// - Note: The release of all players happens asynchronously on the main thread to ensure
    ///   proper cleanup of UI components and main-thread-only resources.
    public static func removeAll() {
        lock.lock()
        let allPlayers = Array(players.values)
        players.removeAll()
        lock.unlock()
        
        // Release all player resources on main thread
        if !allPlayers.isEmpty {
            Task { @MainActor in
                for player in allPlayers {
                    player.cleanup()
                }
            }
        }
    }
    
    /// Returns all currently active player IDs.
    ///
    /// This method is thread-safe and returns a snapshot of all player IDs at the time of calling.
    ///
    /// - Returns: An array of player IDs for all currently managed players
    public static func getAllPlayerIds() -> [Int] {
        lock.lock()
        defer { lock.unlock() }
        return Array(players.keys)
    }
    
    /// Checks if a player with the specified ID exists.
    ///
    /// This method is thread-safe and provides a quick way to check player existence
    /// without retrieving the actual player instance.
    ///
    /// - Parameter playerId: The unique identifier to check for
    /// - Returns: true if a player with the specified ID exists, false otherwise
    public static func playerExists(playerId: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return players[playerId] != nil
    }
}
