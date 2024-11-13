import SwiftUI
import MailKit
import AppKit

class ComposeExtensionViewController: MEExtensionViewController {
    private var anthropicClient: AnthropicClient?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("Mail Extension: viewDidLoad called")
        setupAnthropicClient()
        setupButtons()
    }
    
    private func setupAnthropicClient() {
        anthropicClient = AnthropicClient(apiKey: "YOUR_API_KEY")
    }
    
    private func setupButtons() {
        let grammarButton = NSButton(title: "Check Grammar", target: self, action: #selector(checkGrammar))
        let replyButton = NSButton(title: "Generate Reply", target: self, action: #selector(generateReply))
        
        if let toolbar = view.window?.toolbar {
            let grammarItem = NSToolbarItem(itemIdentifier: .init("grammarCheck"))
            grammarItem.view = grammarButton
            
            let replyItem = NSToolbarItem(itemIdentifier: .init("generateReply"))
            replyItem.view = replyButton
            
            toolbar.insertItem(withItemIdentifier: grammarItem.itemIdentifier, at: 0)
            toolbar.insertItem(withItemIdentifier: replyItem.itemIdentifier, at: 1)
        }
    }
    
    @objc private func checkGrammar() {
        guard let composeContext = extensionContext as? MEComposeSessionContext,
              let session = composeContext.composeSession,
              let messageText = session.subject else {
            showAlert(message: "Could not access message content")
            return
        }
        
        Task {
            do {
                let prompt = """
                Please check the following text for spelling and grammar issues, and suggest improvements:
                \(messageText)
                """
                
                let response = try await anthropicClient?.sendMessage(prompt)
                
                DispatchQueue.main.async {
                    self.showSuggestionsPopover(suggestions: response ?? "No suggestions available")
                }
            } catch {
                showAlert(message: "Error checking grammar: \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func generateReply() {
        guard let composeContext = extensionContext as? MEComposeSessionContext,
              let session = composeContext.composeSession else {
            showAlert(message: "Could not access message session")
            return
        }
        
        Task {
            do {
                // Get the message content
                let subject = session.subject ?? ""
                let sender = session.sender?.rawString ?? ""
                
                let prompt = """
                Based on this email:
                From: \(sender)
                Subject: \(subject)
                
                Please generate an appropriate reply.
                """
                
                let response = try await anthropicClient?.sendMessage(prompt)
                
                DispatchQueue.main.async {
                    if let responseText = response {
                        session.setSubject(responseText)
                    }
                }
            } catch {
                showAlert(message: "Error generating reply: \(error.localizedDescription)")
            }
        }
    }
    
    private func showSuggestionsPopover(suggestions: String) {
        let popover = NSPopover()
        let contentView = NSTextView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))
        contentView.string = suggestions
        contentView.isEditable = false
        
        popover.contentViewController = NSViewController()
        popover.contentViewController?.view = contentView
        popover.behavior = .transient
        
        if let button = view.window?.toolbar?.items.first(where: { $0.itemIdentifier.rawValue == "grammarCheck" })?.view {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    private func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: view.window!)
    }
}
