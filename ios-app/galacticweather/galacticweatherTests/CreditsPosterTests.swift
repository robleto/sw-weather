import XCTest
import UIKit
@testable import galacticweather

/// The Credits strip draws real printed posters from `Assets.xcassets/Posters/`,
/// looked up by a name built at runtime as `"poster-\(world.id)"`.
///
/// That lookup cannot fail at compile time. A renamed imageset, a poster that
/// was never synced, or a world id that doesn't match its filename all produce
/// the same thing: an empty rectangle where a poster should be, on a screen
/// nobody in this project can open — Simulator control is DLP-blocked, so
/// visual verification happens off-machine or not at all. These tests are the
/// substitute.
///
/// Re-sync after adding poster art with `python3 scripts/sync-poster-art.py`.
final class CreditsPosterTests: XCTestCase {

    /// Assets live in the app bundle, not the test bundle. Resolved from a
    /// class that belongs to the app target.
    private var appBundle: Bundle {
        Bundle(for: PassportViewModel.self)
    }

    private func posterImage(_ worldID: String) -> UIImage? {
        UIImage(named: "poster-\(worldID)", in: appBundle, compatibleWith: nil)
    }

    func testFeaturedListIsNonTrivial() {
        // Guards every assertion below from passing vacuously on an empty list.
        XCTAssertGreaterThanOrEqual(CreditsView.featuredWorldIDs.count, 4)
    }

    func testEveryFeaturedWorldHasAPosterAsset() {
        for worldID in CreditsView.featuredWorldIDs {
            XCTAssertNotNil(
                posterImage(worldID),
                "No poster asset named \"poster-\(worldID)\" — run "
                    + "scripts/sync-poster-art.py, and check the source filename "
                    + "in public/posters/ matches the world id"
            )
        }
    }

    func testEveryFeaturedWorldExistsInTheCatalog() {
        for worldID in CreditsView.featuredWorldIDs {
            XCTAssertNotNil(
                getWorld(worldID),
                "\"\(worldID)\" is featured in Credits but is not a world"
            )
        }
    }

    /// The screen's stated rule: nothing shown off in Credits should be
    /// something a free reader cannot actually reach. Alderaan has a poster and
    /// is excluded for exactly this reason, so the rule needs a test or the
    /// next person to add a poster will quietly break it.
    func testNoFeaturedWorldIsPremium() {
        for worldID in CreditsView.featuredWorldIDs {
            guard let world = getWorld(worldID) else { continue }
            XCTAssertFalse(
                world.isPremium,
                "\(world.name) is premium, so a free reader can't visit it — "
                    + "Credits should only feature worlds they can reach"
            )
        }
    }

    /// The posters are portrait 750x1050. `PosterThumb` derives its frame
    /// height from that ratio, so art at a different shape would be cropped by
    /// `.fill` rather than letterboxed — silently, and differently per poster.
    func testPosterArtIsThePortraitShapeTheLayoutAssumes() throws {
        for worldID in CreditsView.featuredWorldIDs {
            let image = try XCTUnwrap(posterImage(worldID), "missing poster for \(worldID)")
            let ratio = image.size.width / image.size.height
            XCTAssertEqual(
                ratio,
                750.0 / 1050.0,
                accuracy: 0.01,
                "\(worldID) poster is \(image.size), not the expected 5:7 portrait"
            )
        }
    }
}
