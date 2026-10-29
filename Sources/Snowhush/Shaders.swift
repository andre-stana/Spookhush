let shaderSource = """
#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float2 viewSize;
    float scale;
    float time;
    float columnWidth;
    int columnCount;
    float pileTop;
    int occluderCount;
    float2 origin;
    float pileBottom;
    float padding;
    float4 light;
    float4 shadowTint;
    float4 lantern;
    float4 flameColor;
};

struct Sprite {
    float2 position;
    float2 velocity;
    float size;
    float alpha;
    float soft;
    float tintAmount;
    float tintRed;
    float tintGreen;
    float tintBlue;
    float lump;
};

struct SpriteOut {
    float4 position [[position]];
    float pointSize [[point_size]];
    float alpha;
    float soft;
    float4 tint;
    float3 light;
    float3 flameColor;
    float2 streak;
    float2 lookDir;
    float radius;
    float lump;
    float spin;
    float lanternGlow;
    float time;
};

static float hash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

vertex SpriteOut spriteVertex(uint vid [[vertex_id]],
                              const device Sprite *sprites [[buffer(0)]],
                              constant Uniforms &u [[buffer(1)]]) {
    Sprite s = sprites[vid];
    bool isCornerPumpkin = s.lump >= 3.0;
    bool isTool = s.lump <= -3.0;
    bool isPumpkin = s.lump >= 2.0 && s.lump < 3.0;
    bool isGoldenLeaf = s.lump < -1.0 && s.lump > -2.5;
    bool isLeaf = s.lump < 0.0 && !isTool;
    bool isClump = s.lump > 0.0 && s.lump < 1.5;

    float pixels = s.size * u.scale;
    float2 streak = float2(0.0);
    if (!isCornerPumpkin && !isTool) {
        float2 travel = s.velocity * (isPumpkin ? 0.006 : isLeaf ? 0.010 : 0.018);
        float smear = min(length(travel), s.size * (isPumpkin ? 0.4 : isLeaf ? 0.9 : (isClump ? 1.2 : 2.0)));
        streak = smear > 0.25 ? normalize(travel) * smear * u.scale : float2(0.0);
    }
    float reach = (isCornerPumpkin || isTool) ? 1.65 : (isPumpkin ? 1.45 : (isGoldenLeaf ? 1.55 : (isLeaf || isClump ? 1.35 : 1.15)));
    float extent = max(pixels * reach + length(streak), 2.0);

    float lanternGlow = 0.0;
    if (u.lantern.z > 0.5) {
        float dist = length(s.position - u.lantern.xy);
        lanternGlow = exp(-dist * dist / (190.0 * 190.0)) * u.lantern.w;
    }

    SpriteOut out;
    out.position = float4(s.position / u.viewSize * 2.0 - 1.0, 0.0, 1.0);
    out.pointSize = extent;
    out.streak = streak / extent;
    out.lookDir = s.velocity;
    out.radius = pixels / extent * 0.5;
    out.alpha = s.alpha * min(pixels / 2.0, 1.0) * pixels / max(pixels + length(streak) * 0.6, 0.001);
    out.soft = s.soft;
    out.tint = float4(s.tintRed, s.tintGreen, s.tintBlue, s.tintAmount);
    out.light = u.light.rgb;
    out.flameColor = u.flameColor.rgb;
    out.lump = s.lump;
    if (isCornerPumpkin) {
        out.spin = sin(u.time * 1.6 + s.lump * 4.0) * 0.035;
    } else if (isTool) {
        out.spin = atan2(s.velocity.y, s.velocity.x);
    } else if (isPumpkin) {
        float seed = s.lump - 2.0;
        out.spin = sin(u.time * 2.2 + seed * 25.0) * 0.28;
    } else if (isGoldenLeaf) {
        float seed = -s.lump - 1.0;
        out.spin = u.time * (seed - 0.5) * 4.2 + seed * 31.0;
    } else if (isLeaf) {
        float seed = -s.lump;
        out.spin = u.time * (seed - 0.5) * 5.2 + seed * 31.0;
    } else if (isClump) {
        out.spin = u.time * (s.lump - 0.5) * 9.0 + s.lump * 40.0;
    } else {
        out.spin = 0.0;
    }
    out.lanternGlow = lanternGlow;
    out.time = u.time;
    return out;
}

fragment float4 spriteFragment(SpriteOut in [[stage_in]], float2 coord [[point_coord]]) {
    float2 p = float2(coord.x - 0.5, 0.5 - coord.y);
    float2 half_ = in.streak * 0.5;
    float span = dot(half_, half_);
    float t = span > 0.0 ? clamp(dot(p, half_) / span, -1.0, 1.0) : 0.0;
    float2 d = p - half_ * t;
    float rad = max(in.radius, 0.001);
    float2 u = d / rad;

    // 0. Interactive Cursor Tool Visuals (Ghost-Vac, Witch Swiffer, Leaf Blower)
    if (in.lump <= -3.0) {
        float r = length(u);
        if (r > 1.55) discard_fragment();

        // Ghost-Vac Vortex Ring (-3.0)
        if (in.lump > -3.5) {
            float angle = atan2(u.y, u.x);
            float swirl = sin(angle * 4.0 - in.time * 14.0 + r * 7.0);
            float ring1 = exp(-pow((r - 0.85) * 4.2, 2.0));
            float ring2 = exp(-pow((r - 0.45) * 5.0, 2.0));
            float core = exp(-r * r * 5.5);
            float spiral = saturate(swirl * 0.5 + 0.5) * exp(-r * 1.4);
            float a = saturate((ring1 * 0.65 + ring2 * 0.55 + spiral * 0.45 + core * 0.5) * in.alpha);
            if (a < 0.004) discard_fragment();
            float3 col = mix(float3(0.45, 0.95, 1.0), in.flameColor, 0.35 + 0.35 * sin(in.time * 6.0 + r * 4.0));
            return float4(col * a, a);
        }

        // Witch Swiffer Broom Pad (-4.0)
        if (in.lump > -4.5) {
            float c = cos(-in.spin + 1.5708), s = sin(-in.spin + 1.5708);
            float2 bp = float2(u.x * c - u.y * s, u.x * s + u.y * c);
            // Wide broom / swiffer bar
            float2 box = abs(bp) - float2(0.95, 0.24);
            float dist = length(max(box, 0.0)) + min(max(box.x, box.y), 0.0);
            float padMask = 1.0 - smoothstep(-0.02, 0.14, dist);
            float glow = exp(-max(dist, 0.0) * 3.5) * 0.42;
            float a = saturate((padMask * 0.85 + glow) * in.alpha);
            if (a < 0.004) discard_fragment();
            float stripe = 0.5 + 0.5 * cos(bp.x * 22.0);
            float3 padCol = mix(float3(0.96, 0.76, 0.22), float3(0.55, 0.95, 0.72), stripe * 0.45);
            float3 col = mix(in.flameColor, padCol, padMask);
            return float4(col * a, a);
        }

        // Leaf Blower Wind Jet (-5.0)
        float c = cos(-in.spin), s = sin(-in.spin);
        float2 wp = float2(u.x * c - u.y * s, u.x * s + u.y * c);
        float cone = abs(wp.y) - (0.18 + max(wp.x + 0.4, 0.0) * 0.55);
        float wave = 0.5 + 0.5 * sin(wp.x * 12.0 - in.time * 22.0);
        float mask = (1.0 - smoothstep(-0.05, 0.25, cone)) * smoothstep(-0.5, 0.9, wp.x) * (1.0 - smoothstep(0.6, 1.35, wp.x));
        float a = saturate(mask * (0.35 + 0.65 * wave) * in.alpha);
        if (a < 0.004) discard_fragment();
        float3 col = mix(float3(0.85, 0.92, 1.0), in.flameColor, 0.45);
        return float4(col * a, a);
    }

    // 1. Giant Sculpted Corner Jack-o'-Lantern (lump >= 3.0)
    if (in.lump >= 3.0) {
        float side = in.lump > 3.5 ? -1.0 : 1.0; // 3.0 = left, 4.0 = right
        float c = cos(in.spin * side), s = sin(in.spin * side);
        float2 lp = float2(u.x * c - u.y * s, u.x * s + u.y * c);
        float excitement = in.tint.a; // 0..1 when cursor touches

        // Curved stem at top
        float2 stemP = lp - float2(0.06 * side * sin(lp.y * 4.0), 0.76);
        bool inStem = abs(stemP.x - 0.08 * side * (lp.y - 0.55)) < 0.13 * (1.18 - (lp.y - 0.58)) && lp.y > 0.52 && lp.y < 1.08;

        // Wide sculpted pumpkin body with 7 deep ribs
        float2 bodyP = float2(lp.x * 0.82, (lp.y + 0.08) * 1.08);
        float bodyR = length(bodyP);
        float ribAngle = lp.x * 6.8;
        float ribWave = cos(ribAngle);
        bodyR -= 0.055 * ribWave * (1.0 - abs(lp.y) * 0.45);

        float bodyAlpha = 1.0 - smoothstep(0.86, 0.97, bodyR);
        float stemAlpha = inStem ? (1.0 - smoothstep(1.0, 1.08, lp.y)) : 0.0;
        float a = max(bodyAlpha, stemAlpha) * in.alpha;

        // Warm outer candle aura
        float flicker = 0.88 + 0.12 * sin(in.time * 11.5 + side * 2.0) * cos(in.time * 17.0) + excitement * 0.35;
        float halo = exp(-dot(u, u) * 1.25) * (0.42 + excitement * 0.28) * in.alpha;
        if (a < 0.002 && halo < 0.002) discard_fragment();

        float3 pumpkinTop = float3(0.98, 0.46, 0.08);
        float3 pumpkinDeep = float3(0.52, 0.14, 0.02);
        float ribShade = saturate(bodyR * 0.72 - ribWave * 0.22 - lp.y * 0.18);
        float3 pumpkinBase = mix(pumpkinTop, pumpkinDeep, ribShade);
        // Rim highlight from top-inner side
        float rimLight = pow(saturate(1.0 - abs(bodyR - 0.78) * 3.5), 2.0) * saturate(lp.y + 0.4);
        pumpkinBase += in.flameColor * rimLight * 0.28;

        // Carved menacing/playful triangular eyes
        float ex = abs(lp.x) - 0.31;
        float ey = lp.y - 0.14;
        bool inEye = ey > -0.11 && ey < 0.22 && abs(ex) < (0.23 - ey) * 0.82;

        // Carved nose triangle
        bool inNose = lp.y > -0.11 && lp.y < 0.04 && abs(lp.x) < (0.05 - lp.y) * 0.75;

        // Carved wide jagged toothy grin
        float mx = abs(lp.x);
        float smileCurve = -0.26 + 0.18 * lp.x * lp.x;
        float my = lp.y - smileCurve;
        float tooth = 0.055 * sign(sin(lp.x * 19.0));
        bool inMouth = mx < 0.56 && abs(my - tooth * 0.35) < 0.135 * (1.0 - mx * 1.15);

        float3 candleCore = min(in.flameColor * (1.35 * flicker) + float3(0.32, 0.24, 0.08), float3(1.0));
        float3 candleRim = in.flameColor * (0.85 * flicker);

        float3 col = pumpkinBase;
        if (inStem && bodyAlpha < 0.5) {
            col = mix(float3(0.28, 0.38, 0.14), float3(0.14, 0.20, 0.07), saturate((lp.y - 0.55) * 2.0));
        } else if (inEye || inNose || inMouth) {
            // Inner carved depth + cursor-watching ember pupil inside eyes
            float2 eyeCenter = float2(sign(lp.x) * 0.31, 0.02) + in.lookDir * 0.08;
            float pupilDist = length(lp - eyeCenter);
            float innerGlow = inEye ? smoothstep(0.18, 0.02, pupilDist) : 0.65;
            col = mix(candleRim, candleCore, innerGlow);
        }

        col *= in.light + in.flameColor * (in.lanternGlow * 0.85 + excitement * 0.5);
        float3 premult = col * a + in.flameColor * halo * (1.0 - a);
        float outA = a + halo * (1.0 - a);
        return float4(premult, outA);
    }

    // 2. Mini Jack-o'-lantern Pumpkin (2.0 <= lump < 3.0)
    if (in.lump >= 2.0) {
        float seed = in.lump - 2.0;
        float c = cos(in.spin), s = sin(in.spin);
        float2 lp = float2(u.x * c - u.y * s, u.x * s + u.y * c);

        // Stem at the top
        float2 stemP = lp - float2(0.03 * sin(lp.y * 6.0), 0.78);
        bool inStem = abs(stemP.x) < 0.13 * (1.1 - (lp.y - 0.65)) && lp.y > 0.58 && lp.y < 1.02;

        // Squat ribbed pumpkin body
        float2 bodyP = float2(lp.x * 0.88, (lp.y + 0.06) * 1.12);
        float bodyR = length(bodyP);
        float ribWave = cos(lp.x * 7.5);
        bodyR -= 0.05 * ribWave * (1.0 - abs(lp.y) * 0.5);

        float bodyAlpha = 1.0 - smoothstep(0.84, 0.98, bodyR);
        float stemAlpha = inStem ? 1.0 : 0.0;
        float a = max(bodyAlpha, stemAlpha) * in.alpha;

        // Warm outer candle halo
        float halo = exp(-dot(u, u) * 1.6) * 0.38 * in.alpha;
        if (a < 0.003 && halo < 0.003) discard_fragment();

        float flicker = 0.86 + 0.14 * sin(in.time * 13.0 + seed * 47.0);
        float3 candleColor = min(in.flameColor * 1.2 + float3(0.2, 0.2, 0.1), float3(1.0)) * flicker;
        float3 pumpkinBase = mix(float3(0.95, 0.42, 0.07), float3(0.58, 0.19, 0.03), saturate(bodyR * 0.75 - ribWave * 0.18));

        // Carved eyes & grin
        float ex = abs(lp.x) - 0.28;
        float ey = lp.y - 0.12;
        bool eye = ey > -0.10 && ey < 0.18 && abs(ex) < (0.18 - ey) * 0.75;
        float mx = abs(lp.x);
        float my = lp.y + 0.22 + 0.07 * cos(lp.x * 5.0);
        float tooth = 0.045 * sign(sin(lp.x * 18.0));
        bool mouth = mx < 0.46 && abs(my - tooth * 0.4) < 0.11 * (1.0 - mx * 1.4);

        float3 col = pumpkinBase;
        if (inStem && bodyAlpha < 0.5) {
            col = float3(0.26, 0.34, 0.14);
        } else if (eye || mouth) {
            col = candleColor * 1.25;
        }
        col *= in.light + in.flameColor * in.lanternGlow * 0.7;
        float3 premult = col * a + in.flameColor * halo * (1.0 - a);
        float outA = a + halo * (1.0 - a);
        return float4(premult, outA);
    }

    // 3. Rare 24k Golden Leaf (-2.5 < lump < -1.0)
    if (in.lump < -1.0) {
        float seed = -in.lump - 1.0;
        float c = cos(in.spin), s = sin(in.spin);
        float2 lp = float2(u.x * c - u.y * s, u.x * s + u.y * c);
        float tilt = 0.58 + 0.42 * abs(cos(in.spin * 0.65 + seed * 12.0));
        lp.y /= tilt;

        float angle = atan2(lp.y, lp.x);
        float lobes = 1.0 + 0.24 * cos(3.0 * angle) + 0.12 * cos(5.0 * angle);
        float r = length(lp * float2(0.85, 1.12)) / max(lobes, 0.35);

        float leafAlpha = (1.0 - smoothstep(0.68, 1.0, r)) * in.alpha;
        // Golden starlight aura around the leaf
        float sparklePulse = 0.75 + 0.25 * sin(in.time * 9.0 + seed * 40.0);
        float aura = exp(-dot(u, u) * 1.45) * 0.48 * sparklePulse * in.alpha;
        if (leafAlpha < 0.002 && aura < 0.002) discard_fragment();

        float vein = exp(-abs(lp.x + 0.07 * sin(lp.y * 4.0)) * 9.5) * saturate(1.0 - r);
        // Moving metallic specular glint band
        float glintWave = pow(saturate(0.5 + 0.5 * sin(in.time * 5.2 + (lp.x * 3.5 + lp.y * 2.5) + seed * 20.0)), 6.0);
        float3 goldBase = mix(float3(1.0, 0.84, 0.18), float3(0.88, 0.56, 0.06), smoothstep(0.25, 0.95, r));
        float3 goldSpec = float3(1.0, 0.98, 0.82);
        float3 color = mix(goldBase, goldSpec, saturate(glintWave * 0.75 + vein * 0.55));
        float3 premult = color * leafAlpha + float3(1.0, 0.85, 0.22) * aura * (1.0 - leafAlpha);
        float outA = leafAlpha + aura * (1.0 - leafAlpha);
        return float4(premult, outA);
    }

    // 4. Autumn Leaf (-1.0 <= lump < 0.0)
    if (in.lump < 0.0) {
        float seed = -in.lump;
        float c = cos(in.spin), s = sin(in.spin);
        float2 lp = float2(u.x * c - u.y * s, u.x * s + u.y * c);
        // 3D tumble foreshortening
        float tilt = 0.52 + 0.48 * abs(cos(in.spin * 0.65 + seed * 12.0));
        lp.y /= tilt;

        float angle = atan2(lp.y, lp.x);
        float lobes = seed > 0.5
            ? 1.0 + 0.22 * cos(3.0 * angle) + 0.10 * cos(5.0 * angle)
            : 1.0 + 0.28 * cos(2.0 * angle) - 0.08 * cos(4.0 * angle);
        float r = length(lp * float2(0.85, 1.15)) / max(lobes, 0.35);

        float a = (1.0 - smoothstep(0.68, 1.0, r)) * in.alpha;
        if (a < 0.002) discard_fragment();

        float vein = exp(-abs(lp.x + 0.08 * sin(lp.y * 4.0)) * 9.0) * saturate(1.0 - r);
        float3 baseTint = in.tint.rgb;
        float3 rimTint = baseTint * float3(0.55, 0.42, 0.32);
        float3 veinTint = min(baseTint * 1.28 + float3(0.12, 0.08, 0.02), float3(1.0));
        float3 color = mix(baseTint, rimTint, smoothstep(0.3, 0.95, r));
        color = mix(color, veinTint, vein * 0.45);
        color *= in.light + in.flameColor * in.lanternGlow * 0.85;
        return float4(color * a, a);
    }

    // 5. Leaf/Ash Clump or Glowing Ember / Spectral Dust
    float r = length(d) / rad;
    float shading = 0.0;
    if (in.lump > 0.0) {
        float angle = atan2(d.y, d.x) + in.spin;
        r /= 1.0 + 0.16 * sin(3.0 * angle) + 0.10 * sin(5.0 * angle + in.lump * 21.0) + 0.06 * sin(2.0 * angle + in.lump * 9.0);
        shading = saturate(dot(u, float2(0.45, -0.6))) * 0.45;
    }
    float head = span > 0.0 ? 0.15 + 0.85 * pow(t * 0.5 + 0.5, 1.5) : 1.0;
    float a = (1.0 - smoothstep(mix(0.55, 0.0, in.soft), 1.0, r)) * in.alpha * head;
    if (a < 0.002) discard_fragment();

    float3 baseColor = mix(float3(1.0, 0.55, 0.14), in.tint.rgb, in.tint.a);
    float3 core = min(baseColor * 1.35 + float3(0.22, 0.16, 0.06), float3(1.0));
    float3 rim = baseColor * 0.52;
    float3 color = mix(core, rim, saturate(smoothstep(0.25, 1.0, r) * 0.7 + shading));
    if (in.lump == 0.0) {
        // Ember / spectral mote glow
        float pulse = 0.82 + 0.18 * sin(in.time * 8.0 + in.tint.r * 31.0);
        color *= pulse * 1.15;
    }
    color *= in.light + in.flameColor * in.lanternGlow * 0.8;
    return float4(color * a, a);
}

struct PileOut {
    float4 position [[position]];
    float2 point;
};

vertex PileOut pileVertex(uint vid [[vertex_id]], constant Uniforms &u [[buffer(0)]]) {
    float2 corner = float2(float(vid & 1), float(vid >> 1));
    float2 p = float2(corner.x * float(u.columnCount) * u.columnWidth, mix(u.pileBottom, u.pileTop, corner.y));
    PileOut out;
    out.position = float4((p + u.origin) / u.viewSize * 2.0 - 1.0, 0.0, 1.0);
    out.point = p;
    return out;
}

static float heightAt(const device float *h, constant Uniforms &u, float x) {
    float f = x / u.columnWidth - 0.5;
    float base = floor(f);
    int i = clamp(int(base), 0, u.columnCount - 1);
    int j = min(i + 1, u.columnCount - 1);
    return mix(h[i], h[j], saturate(f - base));
}

fragment float4 pileFragment(PileOut in [[stage_in]],
                             const device float *heights [[buffer(0)]],
                             constant Uniforms &u [[buffer(1)]],
                             constant float4 *occluders [[buffer(2)]]) {
    float2 world = in.point + u.origin;
    for (int k = 0; k < u.occluderCount; k++) {
        float4 o = occluders[k];
        if (world.x >= o.x && world.x < o.z && world.y >= o.y && world.y < o.w) discard_fragment();
    }

    float x = in.point.x;
    float level = heightAt(heights, u, x);
    float bed = heightAt(heights + u.columnCount, u, x);
    float depth = level - in.point.y;

    // Roughen the top edge slightly so it reads as overlapping autumn leaves
    float leafEdge = (hash(floor(float2(world.x * 0.35, 13.7))) - 0.5) * 1.1;
    float effectiveDepth = depth + leafEdge * saturate((level - bed) / 4.0);

    float coverage = saturate(effectiveDepth * u.scale + 0.5)
        * saturate((in.point.y - bed) * u.scale + 0.5)
        * saturate((level - bed) / 0.75);
    if (coverage <= 0.0) discard_fragment();

    float slope = (heightAt(heights, u, x + 2.0) - heightAt(heights, u, x - 2.0)) * 0.25;
    float light = dot(normalize(float2(-slope, 1.0)), normalize(float2(-0.5, 1.0)));

    // Overlapping autumn leaf mosaic
    float2 leafCell = floor(float2(world.x * 0.22 + sin(world.y * 0.3) * 0.6, world.y * 0.32));
    float leafPick = hash(leafCell);
    float3 leafA = float3(0.82, 0.33, 0.08); // Pumpkin orange
    float3 leafB = float3(0.64, 0.15, 0.10); // Crimson red
    float3 leafC = float3(0.88, 0.55, 0.12); // Golden amber
    float3 leafD = float3(0.42, 0.20, 0.11); // Dark russet
    float3 leafColor = leafPick < 0.32 ? leafA : (leafPick < 0.60 ? leafB : (leafPick < 0.82 ? leafC : leafD));

    float3 shadow = mix(float3(0.18, 0.09, 0.12), u.shadowTint.rgb * 0.45, u.shadowTint.a);
    float3 surface = mix(leafColor, min(u.shadowTint.rgb * 1.1, float3(1.0)), u.shadowTint.a * 0.12);
    float shade = (1.0 - exp(-depth / 22.0)) * 0.55 + (1.0 - light) * 0.45 * exp(-depth / 6.0);
    float3 color = mix(surface, shadow, saturate(shade));
    // Warm golden rim along the top leaves
    color = mix(color, float3(0.98, 0.64, 0.20), exp(-max(depth, 0.0) * 0.85) * 0.38);
    color += (hash(floor(in.position.xy)) - 0.5) * 0.03;

    // Smoldering embers and spectral sparks inside the pile
    float2 emberCell = floor(in.position.xy * 0.35);
    float seed = hash(emberCell + 31.7);
    if (seed > 0.984) {
        float emberPulse = 0.45 + 0.55 * pow(saturate(sin(u.time * (1.2 + seed * 2.4) + seed * 90.0)), 4.0);
        float3 emberCol = seed > 0.996 ? float3(0.75, 0.35, 1.0) : u.flameColor.rgb;
        color = mix(color, emberCol, emberPulse * exp(-depth / 12.0));
    }

    // Nestled glowing Jack-o'-lanterns in deeper piles
    float lanternSpan = 180.0;
    float cellIdx = floor((world.x + 40.0) / lanternSpan);
    float cellSeed = hash(float2(cellIdx, floor(u.origin.y * 0.1) + 7.3));
    if (cellSeed > 0.52) {
        float px = (cellIdx + 0.3 + 0.4 * cellSeed) * lanternSpan - 40.0 - u.origin.x;
        float pLevel = heightAt(heights, u, px);
        float pBed = heightAt(heights + u.columnCount, u, px);
        float pileH = pLevel - pBed;
        if (pileH > 8.5) {
            float py = pBed + min(7.5, pileH * 0.48);
            float2 dp = float2((x - px) / 9.5, (in.point.y - py) / 8.0);
            float dist = length(dp);
            float candleFlicker = 0.85 + 0.15 * sin(u.time * 11.0 + cellSeed * 60.0);
            // Warm glow cast by the nestled pumpkin onto surrounding leaves
            float glowPool = exp(-dist * dist * 0.18) * saturate((pileH - 8.5) / 4.0);
            color += u.flameColor.rgb * glowPool * 0.55 * candleFlicker;

            // Draw the nestled pumpkin itself
            if (dist < 1.05) {
                float rib = cos(dp.x * 6.5) * 0.06;
                float pMask = 1.0 - smoothstep(0.82, 0.98, dist - rib);
                float3 pBody = mix(float3(0.96, 0.42, 0.06), float3(0.55, 0.18, 0.03), saturate(dist * 0.8 - rib * 2.0));
                float ex = abs(dp.x) - 0.30;
                float ey = dp.y - 0.10;
                bool eye = ey > -0.12 && ey < 0.22 && abs(ex) < (0.20 - ey) * 0.8;
                float mx = abs(dp.x);
                float my = dp.y + 0.24 + 0.08 * cos(dp.x * 5.0);
                bool mouth = mx < 0.48 && abs(my) < 0.12 * (1.0 - mx * 1.3);
                if (eye || mouth) {
                    pBody = min(u.flameColor.rgb * 1.2 + float3(0.2, 0.2, 0.1), float3(1.0)) * (1.15 * candleFlicker);
                }
                color = mix(color, pBody, pMask * saturate((pileH - 8.5) / 3.0));
            }
        }
    }

    // Corner Jack-o'-lanterns warm candle pool on the left and right edges
    if (u.flameColor.w > 0.5) {
        float leftDist = length(world - float2(58.0, 32.0));
        float rightDist = length(world - float2(u.viewSize.x - 58.0, 32.0));
        float cornerGlow = (exp(-leftDist * leftDist / (165.0 * 165.0)) + exp(-rightDist * rightDist / (165.0 * 165.0))) * u.lantern.w;
        color += u.flameColor.rgb * cornerGlow * 0.65;
    }

    // Cursor Lantern illumination
    if (u.lantern.z > 0.5) {
        float dist = length(world - u.lantern.xy);
        float lanternPool = exp(-dist * dist / (190.0 * 190.0)) * u.lantern.w;
        color += u.flameColor.rgb * lanternPool * 0.65;
    }

    color *= u.light.rgb;
    return float4(min(color, float3(1.0)) * coverage, coverage);
}
"""
