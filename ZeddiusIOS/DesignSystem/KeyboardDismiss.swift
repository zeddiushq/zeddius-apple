import SwiftUI

extension View {
    /// Adds a "Done" button above the keyboard. Number pads (`.numberPad`,
    /// `.decimalPad`) have no Return key, so without this there's no way to
    /// end editing except tapping another control — which, in a `Form`, can
    /// eat the first tap just to resign first responder, making a toolbar
    /// "Save" button look unresponsive until tapped a second time.
    func dismissKeyboardToolbar() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                    )
                }
            }
        }
    }
}
