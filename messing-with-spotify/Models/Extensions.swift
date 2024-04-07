//
//  Extensions.swift
//  messing-with-spotify
//
//  Created by Preston Clayton on 3/20/23.
//

import Foundation
import Combine
import SwiftUI
import UIKit

extension AnyPublisher {
    func async() async throws -> Output {
        try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = first()
                .sink { result in
                    switch result {
                    case .finished:
                        break
                    case let .failure(error):
                        continuation.resume(throwing: error)
                    }
                    cancellable?.cancel()
                } receiveValue: { value in
                    continuation.resume(with: .success(value))
                }
        }
    }
    
    func async(onDataReceived: @escaping (Output) -> Void) async throws -> Void {
        var cancellable: AnyCancellable?
        do {
            try await withUnsafeThrowingContinuation { continuation in
                cancellable = self
                //may need to change this for running background updates
                    .receive(on: RunLoop.main)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                continuation.resume()
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                        },
                        receiveValue: { value in
                            onDataReceived(value)
                        }
                    )
            }
        } catch {
            cancellable?.cancel()
            throw error
        }
    }
}
