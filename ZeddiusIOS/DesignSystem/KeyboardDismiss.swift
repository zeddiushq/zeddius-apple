import SwiftUI

extension View {
    /// Lets a drag on the Form/List interactively dismiss the keyboard, the
    /// same system gesture Mail/Messages/Settings use — no custom "Done"
    /// button needed. Number pads (`.numberPad`, `.decimalPad`) have no
    /// Return key, so without this there was previously no way to end
    /// editing except tapping another control, which could eat the first
    /// tap just resigning first responder.
    func dismissKeyboardOnScroll() -> some View {
        scrollDismissesKeyboard(.interactively)
    }
}
