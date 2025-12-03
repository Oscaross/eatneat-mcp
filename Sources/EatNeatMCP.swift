//
//  main.swift
//  EatNeatMCP
//
//  Created by Oscar Horner on 18/11/2025.
//
// Temporary MCP server definition to spool up locally.

import Foundation
import FoundationNetworking // distinct module for linux machines on Render
import SwiftMCP
import Dispatch

@MCPServer(name: "EatNeatMCP")
class EatNeatMCP {
    static func main() async {
        let server = EatNeatMCP()
        
        // Use PORT env var when running on Render, default to 8080 for local tests
        let portEnv = ProcessInfo.processInfo.environment["PORT"]
        let port = Int(portEnv ?? "8080") ?? 8080

        let transport = HTTPSSETransport(server: server, host: "0.0.0.0", port: port)

        // Auth layer
        if let token = ProcessInfo.processInfo.environment["MCP_TOKEN"] {
            transport.authorizationHandler = { bearer in
                guard let bearer, bearer == token else {
                    return .unauthorized("Invalid token")
                }
                return .authorized
            }
        }

        print("[MCP] EatNeatMCP HTTP+SSE server starting on port \(port)")
        
        do {
            try await transport.run()
        } catch {
            print("Error with MCP server starting.")
        }
    }
    

    /// Sends a popup command into the EatNeat AppBridge.
    @MCPTool(
        description: "Show a popup notification inside the EatNeat app."
    )
    func showPopup(message: String) async throws -> [String: String] {

        let payload: [String: Any] = [
            "action": "showPopup",
            "message": message
        ]

        try await postToAppBridge(payload: payload)

        return [
            "status": "sent",
            "echo": message
        ]
    }
    
    
    /// Registers a match between a foodbank need and a user's pantry item, for a specified foodbank.
    struct RegisterItemNeedMatchResult: Codable {
        let status: String
        let foodbankId: String
        let needId: Int
        let itemId: String
    }

    @MCPTool(
        description: """
        Register a match between a user's pantry item and a foodbank need. \
        Call this when you decide an item closely matches a need. \
        Do NOT map the same item to more than one need.
        """
    )
    func registerItemNeedMatch(itemId: String, needId: Int, foodbankId: String) async throws -> RegisterItemNeedMatchResult {
        print("[MCP TOOL] Trying to register match: item \(itemId) -> need \(needId) at foodbank \(foodbankId)")
        
        let payload: [String: Any] = [
            "matchItemToNeed": [
                "id": UUID().uuidString,
                "foodbankID": foodbankId,
                "needID": needId,
                "itemID": itemId
            ]
        ]

        try await postToAppBridge(payload: payload)

        return RegisterItemNeedMatchResult(
            status: "ok",
            foodbankId: foodbankId,
            needId: needId,
            itemId: itemId
        )
    }


    /// An MCP tool receives a command from its agent, and redirects traffic to this function. Posts an HTTP request to the client (iOS app) through sending a bridge command, triggering the view model to change on the client side.
    private func postToAppBridge(payload: [String: Any]) async throws {
        guard let url = URL(string: "http://127.0.0.1:9090") else {
            throw NSError(domain: "MCP", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid AppBridge URL"])
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (_, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "MCP", code: 2,
                userInfo: [NSLocalizedDescriptionKey: "AppBridge returned non-200 status"])
        }
    }
}

@main
struct EatNeatMCPMain {
    static func main() async {
        await EatNeatMCP.main()
    }
}
