//
//  BodyMapView.swift
//  No Limits
//
//  Created by Sukhman Singh on 3/5/26.
//

import SwiftUI

struct BodyMapView: View {
    let muscleRanks: [MuscleGroup: Rank]

    // Image is 848 x 1264 px
    private let imageAspect: CGFloat = 848.0 / 1264.0

    var body: some View {
        ZStack {
            // Layer 1: Colored muscle zones
            Canvas { ctx, size in
                let w = size.width
                let h = size.height

                // Clip to body outline so zone color can't leak outside the figure
                ctx.clip(to: bodyOutlinePath(w: w, h: h))

                for zone in allZones {
                    let rank = muscleRanks[zone.muscle] ?? .iron
                    let path = zone.buildPath(in: w, h: h)
                    ctx.fill(path, with: .color(rank.color.opacity(0.85)))
                }
            }

            // Layer 2: Anatomy image — multiply blends colors with muscle detail
            // White × color = color (shows through), Gray × color = darker (adds definition)
            Image("body-silhouette")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .blendMode(.multiply)
        }
        .compositingGroup()
        .aspectRatio(imageAspect, contentMode: .fit)
    }

    // MARK: - Body Outline Clip Path

    private func bodyOutlinePath(w: CGFloat, h: CGFloat) -> Path {
        var p = Path()
        // Trace clockwise from top of head
        let pts: [(CGFloat, CGFloat)] = [
            // Top of head
            (0.44, 0.025), (0.56, 0.025),
            // Right side of head
            (0.585, 0.05), (0.59, 0.08), (0.575, 0.11),
            // Neck right
            (0.56, 0.13), (0.58, 0.14),
            // Right trap to shoulder
            (0.65, 0.145), (0.72, 0.155), (0.78, 0.165),
            // Right deltoid outer
            (0.86, 0.185), (0.88, 0.20),
            // Right upper arm outer
            (0.895, 0.24), (0.90, 0.28), (0.895, 0.32),
            // Right elbow
            (0.89, 0.345), (0.885, 0.36),
            // Right forearm outer
            (0.90, 0.40), (0.91, 0.43),
            // Right hand
            (0.93, 0.46), (0.935, 0.49), (0.92, 0.50),
            (0.90, 0.49),
            // Right forearm inner
            (0.87, 0.44), (0.85, 0.40), (0.84, 0.37),
            // Right elbow inner
            (0.83, 0.345),
            // Right arm inner to torso
            (0.81, 0.32), (0.78, 0.28), (0.76, 0.24),
            // Right torso
            (0.73, 0.22), (0.72, 0.28), (0.71, 0.34),
            (0.70, 0.40), (0.695, 0.42),
            // Right hip
            (0.72, 0.44), (0.73, 0.46),
            // Right outer thigh
            (0.73, 0.50), (0.72, 0.56), (0.70, 0.62),
            (0.685, 0.65),
            // Right knee
            (0.69, 0.67), (0.69, 0.70),
            // Right calf outer
            (0.70, 0.73), (0.695, 0.78), (0.68, 0.83),
            // Right ankle/foot
            (0.67, 0.88), (0.665, 0.92), (0.67, 0.95),
            (0.64, 0.965), (0.58, 0.96),
            // Right foot inner
            (0.57, 0.93), (0.575, 0.90),
            // Right calf inner
            (0.58, 0.85), (0.585, 0.80), (0.58, 0.75),
            (0.575, 0.70),
            // Right inner thigh
            (0.58, 0.67), (0.57, 0.62), (0.56, 0.56),
            (0.545, 0.50),
            // Crotch
            (0.52, 0.475), (0.50, 0.47), (0.48, 0.475),
            // Left inner thigh
            (0.455, 0.50),
            (0.44, 0.56), (0.43, 0.62), (0.42, 0.67),
            // Left calf inner
            (0.425, 0.70), (0.42, 0.75), (0.415, 0.80),
            (0.42, 0.85),
            // Left foot inner
            (0.425, 0.90), (0.43, 0.93),
            (0.42, 0.96), (0.36, 0.965),
            // Left ankle/foot
            (0.33, 0.95), (0.335, 0.92), (0.33, 0.88),
            // Left calf outer
            (0.32, 0.83), (0.305, 0.78), (0.30, 0.73),
            // Left knee
            (0.31, 0.70), (0.31, 0.67),
            (0.315, 0.65),
            // Left outer thigh
            (0.30, 0.62), (0.28, 0.56), (0.27, 0.50),
            // Left hip
            (0.27, 0.46), (0.28, 0.44),
            // Left torso
            (0.305, 0.42), (0.30, 0.40), (0.29, 0.34),
            (0.28, 0.28), (0.27, 0.22),
            // Left arm inner to torso
            (0.24, 0.24), (0.22, 0.28), (0.19, 0.32),
            // Left elbow inner
            (0.17, 0.345),
            // Left forearm inner
            (0.16, 0.37), (0.15, 0.40), (0.13, 0.44),
            (0.10, 0.49),
            // Left hand
            (0.08, 0.50), (0.065, 0.49), (0.07, 0.46),
            // Left forearm outer
            (0.09, 0.43), (0.10, 0.40), (0.105, 0.36),
            // Left elbow
            (0.11, 0.345),
            (0.105, 0.32), (0.10, 0.28), (0.105, 0.24),
            // Left upper arm outer
            (0.12, 0.20), (0.14, 0.185),
            // Left deltoid
            (0.22, 0.165), (0.28, 0.155), (0.35, 0.145),
            // Left neck
            (0.42, 0.14), (0.44, 0.13),
            // Left side of head
            (0.425, 0.11), (0.41, 0.08), (0.415, 0.05),
        ]
        guard let first = pts.first else { return p }
        p.move(to: CGPoint(x: first.0 * w, y: first.1 * h))
        for pt in pts.dropFirst() {
            p.addLine(to: CGPoint(x: pt.0 * w, y: pt.1 * h))
        }
        p.closeSubpath()
        return p
    }

    // MARK: - Zone Definitions
    // Normalized 0–1 coords mapped to the 848×1264 anatomy image

    var allZones: [NormalizedZone] {
        [
            // -- SHOULDERS / DELTOIDS --
            // Left deltoid: rounded cap from trap to upper arm
            NormalizedZone(muscle: .shoulders, points: [
                (0.14, 0.175), (0.19, 0.155), (0.26, 0.155),
                (0.26, 0.215), (0.19, 0.225), (0.12, 0.205)
            ]),
            // Right deltoid
            NormalizedZone(muscle: .shoulders, points: [
                (0.86, 0.175), (0.81, 0.155), (0.74, 0.155),
                (0.74, 0.215), (0.81, 0.225), (0.88, 0.205)
            ]),

            // -- UPPER CHEST (clavicular / upper pec region) --
            NormalizedZone(muscle: .upperChest, points: [
                (0.33, 0.155), (0.50, 0.148), (0.67, 0.155),
                (0.66, 0.195), (0.50, 0.188), (0.34, 0.195)
            ]),

            // -- CHEST / PECTORALS --
            // Left pec
            NormalizedZone(muscle: .chest, points: [
                (0.27, 0.195), (0.45, 0.19), (0.46, 0.255),
                (0.40, 0.265), (0.30, 0.255), (0.26, 0.225)
            ]),
            // Right pec
            NormalizedZone(muscle: .chest, points: [
                (0.73, 0.195), (0.55, 0.19), (0.54, 0.255),
                (0.60, 0.265), (0.70, 0.255), (0.74, 0.225)
            ]),

            // -- LATS (visible as side torso panels below armpits) --
            // Left lat
            NormalizedZone(muscle: .lats, points: [
                (0.26, 0.225), (0.32, 0.25), (0.34, 0.30),
                (0.33, 0.38), (0.30, 0.40), (0.27, 0.36), (0.26, 0.28)
            ]),
            // Right lat
            NormalizedZone(muscle: .lats, points: [
                (0.74, 0.225), (0.68, 0.25), (0.66, 0.30),
                (0.67, 0.38), (0.70, 0.40), (0.73, 0.36), (0.74, 0.28)
            ]),

            // -- BICEPS (inner/front of upper arm) --
            // Left bicep
            NormalizedZone(muscle: .biceps, points: [
                (0.18, 0.225), (0.245, 0.22),
                (0.22, 0.27), (0.19, 0.33),
                (0.155, 0.33), (0.155, 0.27)
            ]),
            // Right bicep
            NormalizedZone(muscle: .biceps, points: [
                (0.82, 0.225), (0.755, 0.22),
                (0.78, 0.27), (0.81, 0.33),
                (0.845, 0.33), (0.845, 0.27)
            ]),

            // -- TRICEPS (outer/back of upper arm) --
            // Left tricep
            NormalizedZone(muscle: .triceps, points: [
                (0.115, 0.21), (0.17, 0.225),
                (0.155, 0.27), (0.14, 0.33),
                (0.095, 0.32), (0.095, 0.26)
            ]),
            // Right tricep
            NormalizedZone(muscle: .triceps, points: [
                (0.885, 0.21), (0.83, 0.225),
                (0.845, 0.27), (0.86, 0.33),
                (0.905, 0.32), (0.905, 0.26)
            ]),

            // -- ABDOMINALS --
            NormalizedZone(muscle: .abdominals, points: [
                (0.38, 0.265), (0.50, 0.26), (0.62, 0.265),
                (0.63, 0.34), (0.62, 0.41), (0.50, 0.42),
                (0.38, 0.41), (0.37, 0.34)
            ]),

            // -- QUADS (front of thigh, hip to knee) --
            // Left quad
            NormalizedZone(muscle: .quads, points: [
                (0.30, 0.44), (0.44, 0.435),
                (0.46, 0.48), (0.45, 0.55),
                (0.43, 0.62), (0.42, 0.655),
                (0.34, 0.66), (0.31, 0.60),
                (0.29, 0.52)
            ]),
            // Right quad
            NormalizedZone(muscle: .quads, points: [
                (0.70, 0.44), (0.56, 0.435),
                (0.54, 0.48), (0.55, 0.55),
                (0.57, 0.62), (0.58, 0.655),
                (0.66, 0.66), (0.69, 0.60),
                (0.71, 0.52)
            ]),

            // -- HAMSTRINGS (outer thigh edges — rear thigh representation) --
            // Left hamstring
            NormalizedZone(muscle: .hamstrings, points: [
                (0.27, 0.44), (0.31, 0.44),
                (0.30, 0.52), (0.29, 0.60),
                (0.31, 0.655), (0.27, 0.63), (0.265, 0.52)
            ]),
            // Right hamstring
            NormalizedZone(muscle: .hamstrings, points: [
                (0.73, 0.44), (0.69, 0.44),
                (0.70, 0.52), (0.71, 0.60),
                (0.69, 0.655), (0.73, 0.63), (0.735, 0.52)
            ]),

            // -- CALVES (lower leg from knee to ankle) --
            // Left calf
            NormalizedZone(muscle: .legs, points: [
                (0.31, 0.67), (0.43, 0.67),
                (0.435, 0.73), (0.425, 0.80),
                (0.41, 0.87), (0.34, 0.87),
                (0.315, 0.80), (0.30, 0.73)
            ]),
            // Right calf
            NormalizedZone(muscle: .legs, points: [
                (0.69, 0.67), (0.57, 0.67),
                (0.565, 0.73), (0.575, 0.80),
                (0.59, 0.87), (0.66, 0.87),
                (0.685, 0.80), (0.70, 0.73)
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
        LinearGradient.screenBg.ignoresSafeArea()
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
