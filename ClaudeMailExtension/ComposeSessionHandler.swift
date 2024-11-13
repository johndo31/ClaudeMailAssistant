//
//  ComposeSessionHandler.swift
//  ClaudeMailAssistant
//
//  Created by Jan Niklas Sikorra on 13.11.24.
//
import MailKit

@available(macOS 11.0, *)
class ComposeSessionHandler: NSObject, MEExtension {
    static func getExtensionViewController() -> MEExtensionViewController {
        return ComposeExtensionViewController()
    }
}
