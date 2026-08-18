import SwiftUI

/// Lets a full-screen cover be thrown off the bottom of the phone the way the
/// weather screen is (`ContentView.tossGesture`): the screen follows the
/// finger down, and past a distance — or on a flick that would have travelled
/// one — it goes the rest of the way and dismisses. Atlas and Passport are
/// both reached from the list, so tossing them lands you back on it, which is
/// the same place the weather screen's toss leads.
///
/// The weather screen can be grabbed anywhere on its surface because the
/// `TabView` under it only claims horizontal drags. Atlas and Passport are
/// scrolling screens, and a scroll view claims vertical ones — so the toss is
/// offered only while the content is already at its top, which is the rule a
/// system sheet follows too. That's what `tossScrollAnchor()` is for: it
/// reports where the scrolled content is sitting, and without it a screen
/// would only ever be tossable from wherever it happened to be scrolled to.
///
/// Deliberately no `GeometryReader` here. Wrapping the screen in one would
/// hand it the reader's layout rules — content sized to itself rather than to
/// the screen, and safe areas resolved at the wrong level — and both of these
/// screens are full-bleed. The two places the screen height would have been
/// used are constants instead, and documented where they're used.
struct TossToDismiss: ViewModifier {
    fileprivate static let coordinateSpace = "toss-to-dismiss"

    /// Roughly a fifth of a phone, matching the proportion the weather
    /// screen's own threshold works out to.
    private static let dragThreshold: CGFloat = 170
    /// Past the tallest phone, so the screen is gone rather than merely
    /// mostly-gone when the animation ends. It also has to clear the safe
    /// areas the art bleeds into — the same overshoot `tossGesture` documents.
    private static let travel: CGFloat = 1400

    let onDismiss: () -> Void

    @State private var offset: CGFloat = 0
    @State private var scrollTop: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .coordinateSpace(.named(Self.coordinateSpace))
            .onPreferenceChange(TossScrollAnchorKey.self) { scrollTop = $0 }
            // `simultaneous` so the scroll view keeps working: this gesture
            // only ever acts on a downward drag that starts at the top, and
            // has to stay out of the way of every other one.
            .simultaneousGesture(gesture)
    }

    private var gesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                guard isAtTop else { return }
                // Downward and vertical-dominant only, so a diagonal drag
                // across a list of worlds doesn't start dragging the screen.
                guard value.translation.height > 0,
                      abs(value.translation.height) > abs(value.translation.width)
                else { return }
                offset = value.translation.height
            }
            .onEnded { value in
                // Nothing was picked up — the drag started mid-scroll, or went
                // the wrong way — so there's nothing to throw or put back.
                guard offset > 0 else { return }

                // Velocity counts as much as distance: a short, fast flick is
                // a toss, and shouldn't have to travel as far as a slow
                // deliberate drag.
                let flung = value.predictedEndTranslation.height > 420
                let dragged = value.translation.height > Self.dragThreshold
                guard flung || dragged else {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        offset = 0
                    }
                    return
                }

                withAnimation(.easeIn(duration: 0.22)) {
                    offset = Self.travel
                } completion: {
                    onDismiss()
                }
            }
    }

    /// A hair of slack, because a list resting at the top reports a fraction
    /// off zero mid-bounce and a toss shouldn't be refused for it.
    private var isAtTop: Bool { scrollTop > -1 }
}

/// How far the scrolled content sits from the top of its screen: 0 at rest,
/// negative once scrolled down.
private struct TossScrollAnchorKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    /// Throwable-off-the-bottom, like the weather screen. Pair it with
    /// `tossScrollAnchor()` on the scrolling content inside.
    func tossToDismiss(onDismiss: @escaping () -> Void) -> some View {
        modifier(TossToDismiss(onDismiss: onDismiss))
    }

    /// Apply to a scroll view's content, *outside* its padding — the padding
    /// is part of what sits at the top of the screen at rest, and measuring
    /// inside it would report a screen scrolled to the top as already several
    /// dozen points down.
    func tossScrollAnchor() -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: TossScrollAnchorKey.self,
                    value: proxy.frame(in: .named(TossToDismiss.coordinateSpace)).minY
                )
            }
        )
    }
}
