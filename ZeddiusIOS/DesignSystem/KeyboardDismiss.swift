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
                // A bare Button here renders flush against the keys with no
                // breathing room — wrapping it in its own bar (padding +
                // background) makes it read as a proper accessory bar
                // attached to the keyboard, matching system keyboards.
                HStack {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
                        )
                    }
                    .fontWeight(.semibold)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
    }
}
