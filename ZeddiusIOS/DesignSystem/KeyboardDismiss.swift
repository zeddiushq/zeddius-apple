import SwiftUI

extension View {
    /// Any swipe on the Form/List dismisses the keyboard immediately —
    /// matches apps like GitHub, where the keyboard snaps away the moment
    /// a swipe starts. `.interactively` (tracking the keyboard down under
    /// your finger as you drag) feels slow by comparison; `.immediately`
    /// is the snappier one-shot dismiss. Applies the same way regardless
    /// of keyboard type. Number pads (`.numberPad`, `.decimalPad`) have no
    /// Return key, so without this there was previously no way to end
    /// editing except tapping another control, which could eat the first
    /// tap just resigning first responder.
    func dismissKeyboardOnScroll() -> some View {
        scrollDismissesKeyboard(.immediately)
    }
}
