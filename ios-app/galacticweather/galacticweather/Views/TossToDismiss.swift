import SwiftUI

/// Throws a screen off the bottom of the phone the way the weather screen is
/// thrown (`ContentView.tossGesture`): it follows the finger down, and a flick
/// — or a long enough drag — sends it the rest of the way and dismisses.
///
/// **This is a handle, not a whole surface, and it can't be a whole surface.**
/// The weather screen can be grabbed anywhere because the `TabView` under it
/// claims horizontal drags only. Atlas and Passport are scrolling screens, and
/// a scroll view claims vertical ones — so a full-surface version fights it in
/// two ways at once. Every downward drag at the top moved the screen *and*
/// rubber-banded the list, so the content travelled further than the finger;
/// and scrolling back up turned into a dismissal the instant the list reached
/// its top, which made the screens hard to simply read.
///
/// Attaching it to the header instead is the same answer `SavedLocationsView`
/// already reached, for the same reason. `highPriorityGesture` is what keeps
/// the scroll view out of it: a drag starting on the header belongs to the
/// toss, and the list underneath never moves. The trade is that a screen
/// scrolled down has no handle showing, which is the right way round — mid-
/// list, a downward drag is someone scrolling back up.
///
/// Keep the handle off anything tappable. The X sits in the same header, and
/// a drag gesture over a button is a good way to make the button feel broken.
extension View {
    /// The grab area. Pair with `.offset(y:)` on the screen root, bound to the
    /// same value.
    ///
    /// `isEnabled` is a gesture mask rather than an `if` around the modifier,
    /// so the handle's view identity doesn't change with it — and a screen
    /// that opted out keeps a perfectly ordinary, draggable-to-scroll header.
    func tossHandle(
        offset: Binding<CGFloat>,
        isEnabled: Bool = true,
        onDismiss: @escaping () -> Void
    ) -> some View {
        // The handle is text and empty space, neither of which is hit-testable
        // on its own.
        contentShape(Rectangle())
            .highPriorityGesture(
                TossGesture(offset: offset, onDismiss: onDismiss).body,
                including: isEnabled ? .all : .subviews
            )
    }
}

private struct TossGesture {
    /// Roughly a fifth of a phone, matching the proportion the weather
    /// screen's own threshold works out to.
    private static let dragThreshold: CGFloat = 170
    /// Past the tallest phone, so the screen is gone rather than merely
    /// mostly-gone when the animation ends. It also has to clear the safe
    /// areas the art bleeds into — the same overshoot `tossGesture` documents.
    private static let travel: CGFloat = 1400

    let offset: Binding<CGFloat>
    let onDismiss: () -> Void

    var body: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                // Downward and vertical-dominant only, so a sideways drag
                // across the header doesn't start dragging the screen.
                guard value.translation.height > 0,
                      abs(value.translation.height) > abs(value.translation.width)
                else { return }
                offset.wrappedValue = value.translation.height
            }
            .onEnded { value in
                // Nothing was picked up — the drag went the wrong way — so
                // there's nothing to throw or to put back.
                guard offset.wrappedValue > 0 else { return }

                // Velocity counts as much as distance: a short, fast flick is
                // a toss, and shouldn't have to travel as far as a slow
                // deliberate drag.
                let flung = value.predictedEndTranslation.height > 420
                let dragged = value.translation.height > Self.dragThreshold
                guard flung || dragged else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        offset.wrappedValue = 0
                    }
                    return
                }

                withAnimation(.easeIn(duration: 0.22)) {
                    offset.wrappedValue = Self.travel
                } completion: {
                    onDismiss()
                }
            }
    }
}
