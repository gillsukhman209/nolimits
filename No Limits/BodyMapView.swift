//
//  BodyMapView.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI

struct BodyMapView: View {
    let muscleRanks: [MuscleGroup: Rank]

    var body: some View {
        // Colored zones masked by the silhouette — colors only show inside the body
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            for zone in allZones {
                let rank = muscleRanks[zone.muscle] ?? .iron
                let opacity: CGFloat = zone.muscle == .hamstrings ? 0.65 : 0.85
                let path = zone.buildPath(in: w, h: h)
                ctx.fill(path, with: .color(rank.color.opacity(opacity)))
            }
        }
        .mask {
            Image("body-silhouette")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .overlay {
            Image("body-silhouette")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.white.opacity(0.03))
        }
        .aspectRatio(1024.0 / 1536.0, contentMode: .fit)
    }

    // MARK: - Zone Definitions
    // Normalized 0–1 coords. Zones are intentionally LARGE and overlapping.
    // The mask clips everything to the body shape, so overflow is invisible.

    var allZones: [NormalizedZone] {
        [
            // -- SHOULDERS (big deltoid caps from neck to upper arm) --
            NormalizedZone(muscle: .shoulders, points: [
                (0.17, 0.15), (0.28, 0.13), (0.40, 0.15),
                (0.40, 0.24), (0.28, 0.24), (0.17, 0.22)
            ]),
            NormalizedZone(muscle: .shoulders, points: [
                (0.83, 0.15), (0.72, 0.13), (0.60, 0.15),
                (0.60, 0.24), (0.72, 0.24), (0.83, 0.22)
            ]),

            // -- UPPER CHEST (wide band across upper torso) --
            NormalizedZone(muscle: .upperChest, points: [
                (0.33, 0.16), (0.50, 0.15), (0.67, 0.16),
                (0.67, 0.24), (0.50, 0.23), (0.33, 0.24)
            ]),

            // -- CHEST (big pec shapes) --
            NormalizedZone(muscle: .chest, points: [
                (0.30, 0.22), (0.50, 0.21), (0.50, 0.34),
                (0.44, 0.35), (0.34, 0.33), (0.28, 0.28)
            ]),
            NormalizedZone(muscle: .chest, points: [
                (0.70, 0.22), (0.50, 0.21), (0.50, 0.34),
                (0.56, 0.35), (0.66, 0.33), (0.72, 0.28)
            ]),

            // -- LATS (side panels of torso, overlapping with chest) --
            NormalizedZone(muscle: .lats, points: [
                (0.26, 0.24), (0.36, 0.26), (0.38, 0.34),
                (0.37, 0.42), (0.28, 0.42), (0.24, 0.34)
            ]),
            NormalizedZone(muscle: .lats, points: [
                (0.74, 0.24), (0.64, 0.26), (0.62, 0.34),
                (0.63, 0.42), (0.72, 0.42), (0.76, 0.34)
            ]),

            // -- BICEPS (front of upper arm, generous) --
            NormalizedZone(muscle: .biceps, points: [
                (0.20, 0.19), (0.30, 0.20), (0.32, 0.28),
                (0.30, 0.36), (0.22, 0.38), (0.16, 0.32), (0.15, 0.24)
            ]),
            NormalizedZone(muscle: .biceps, points: [
                (0.80, 0.19), (0.70, 0.20), (0.68, 0.28),
                (0.70, 0.36), (0.78, 0.38), (0.84, 0.32), (0.85, 0.24)
            ]),

            // -- TRICEPS (outer arm, extends down to forearm area) --
            NormalizedZone(muscle: .triceps, points: [
                (0.15, 0.22), (0.20, 0.22), (0.22, 0.34),
                (0.20, 0.42), (0.14, 0.42), (0.10, 0.34), (0.10, 0.26)
            ]),
            NormalizedZone(muscle: .triceps, points: [
                (0.85, 0.22), (0.80, 0.22), (0.78, 0.34),
                (0.80, 0.42), (0.86, 0.42), (0.90, 0.34), (0.90, 0.26)
            ]),

            // -- ABDOMINALS (wide center torso from chest to hips) --
            NormalizedZone(muscle: .abdominals, points: [
                (0.36, 0.32), (0.50, 0.30), (0.64, 0.32),
                (0.66, 0.40), (0.64, 0.48), (0.50, 0.50),
                (0.36, 0.48), (0.34, 0.40)
            ]),

            // -- QUADS (big front-of-thigh shapes, hip to knee) --
            NormalizedZone(muscle: .quads, points: [
                (0.30, 0.46), (0.48, 0.44), (0.50, 0.50),
                (0.50, 0.62), (0.48, 0.72), (0.44, 0.72),
                (0.36, 0.68), (0.30, 0.60), (0.28, 0.52)
            ]),
            NormalizedZone(muscle: .quads, points: [
                (0.70, 0.46), (0.52, 0.44), (0.50, 0.50),
                (0.50, 0.62), (0.52, 0.72), (0.56, 0.72),
                (0.64, 0.68), (0.70, 0.60), (0.72, 0.52)
            ]),

            // -- HAMSTRINGS (outer thigh edges, slightly behind quads) --
            NormalizedZone(muscle: .hamstrings, points: [
                (0.26, 0.46), (0.32, 0.46), (0.30, 0.56),
                (0.28, 0.66), (0.30, 0.72), (0.24, 0.68), (0.22, 0.56)
            ]),
            NormalizedZone(muscle: .hamstrings, points: [
                (0.74, 0.46), (0.68, 0.46), (0.70, 0.56),
                (0.72, 0.66), (0.70, 0.72), (0.76, 0.68), (0.78, 0.56)
            ]),

            // -- CALVES (entire lower leg from knee to ankle) --
            NormalizedZone(muscle: .legs, points: [
                (0.28, 0.70), (0.48, 0.70), (0.48, 0.80),
                (0.46, 0.90), (0.42, 0.96), (0.34, 0.96),
                (0.30, 0.90), (0.28, 0.80)
            ]),
            NormalizedZone(muscle: .legs, points: [
                (0.72, 0.70), (0.52, 0.70), (0.52, 0.80),
                (0.54, 0.90), (0.58, 0.96), (0.66, 0.96),
                (0.70, 0.90), (0.72, 0.80)
            ]),
        ]
    }
}

// MARK: - Normalized Zone

struct NormalizedZone {
    let muscle: MuscleGroup
    let points: [(CGFloat, CGFloat)]

    func buildPath(in w: CGFloat, h: CGFloat) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: CGPoint(x: first.0 * w, y: first.1 * h))
        for pt in points.dropFirst() {
            path.addLine(to: CGPoint(x: pt.0 * w, y: pt.1 * h))
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        Color.appBg.ignoresSafeArea()
        BodyMapView(muscleRanks: [
            .chest: .gold,
            .upperChest: .silver,
            .shoulders: .platinum,
            .biceps: .bronze,
            .triceps: .iron,
            .lats: .diamond,
            .abdominals: .silver,
            .quads: .gold,
            .hamstrings: .bronze,
            .legs: .iron,
        ])
        .padding(20)
    }
}
