cbuffer Uniforms : register(b0) {
    float2 viewSize;
    float scale;
    float time;
    float columnWidth;
    int columnCount;
    float pileTop;
    int occluderCount;
    float2 origin;
    float pileBottom;
    int heightOffset;
    float4 light;
    float4 shadowTint;
    float4 lantern;
    float4 occluders[16];
};

Buffer<float> heights : register(t0);

struct SpriteIn {
    float2 position : POSITION;
    float2 velocity : VELOCITY;
    float size : SIZE;
    float alpha : ALPHA;
    float soft : SOFT;
    float tintAmount : TINTAMOUNT;
    float3 tintColor : TINTCOLOR;
    float lump : LUMP;
    uint vid : SV_VertexID;
};

struct SpriteOut {
    float4 position : SV_Position;
    float2 coord : TEXCOORD0;
    float alpha : ALPHA;
    float soft : SOFT;
    float4 tint : TINT;
    float2 streak : STREAK;
    float radius : RADIUS;
    float lump : LUMP;
    float spin : SPIN;
};

float hash(float2 p) {
    p = frac(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return frac(p.x * p.y);
}

SpriteOut spriteVertex(SpriteIn s) {
    bool isCornerPumpkin = s.lump >= 3.0;
    bool isPumpkin = s.lump >= 2.0 && s.lump < 3.0;
    bool isTool = s.lump <= -2.5 && s.lump >= -6.5;
    bool isGoldenLeaf = s.lump < -1.0 && s.lump > -2.9;
    bool isLeaf = s.lump < 0.0 && !isTool;
    bool isClump = s.lump > 0.0 && s.lump < 1.5;

    float pixels = s.size * scale;
    float2 streak = float2(0.0, 0.0);
    if (!isCornerPumpkin && !isTool) {
        float2 travel = s.velocity * (isPumpkin ? 0.006 : isLeaf ? 0.010 : 0.018);
        float smear = min(length(travel), s.size * (isPumpkin ? 0.4 : isLeaf ? 0.9 : (isClump ? 1.2 : 2.0)));
        streak = smear > 0.25 ? normalize(travel) * smear * scale : float2(0.0, 0.0);
    }
    float reach = isCornerPumpkin ? 1.65 : (isTool ? 1.65 : (isPumpkin ? 1.45 : (isGoldenLeaf ? 2.15 : (isLeaf || isClump ? 1.35 : 1.15))));
    float extent = max(pixels * reach + length(streak), 2.0);
    float2 corner = float2(float(s.vid & 1), float(s.vid >> 1));
    SpriteOut o;
    float2 center = s.position / viewSize * 2.0 - 1.0;
    o.position = float4(center + (corner - 0.5) * extent * 2.0 / (viewSize * scale), 0.0, 1.0);
    o.coord = float2(corner.x, 1.0 - corner.y);
    o.streak = isCornerPumpkin ? s.velocity : (streak / extent);
    o.radius = pixels / extent * 0.5;
    o.alpha = s.alpha * min(pixels / 2.0, 1.0) * pixels / max(pixels + length(streak) * 0.6, 0.001);
    o.soft = s.soft;
    o.tint = float4(s.tintColor, s.tintAmount);
    o.lump = s.lump;
    if (isCornerPumpkin) {
        o.spin = sin(time * 1.6 + s.lump * 4.0) * 0.035;
    } else if (isTool) {
        o.spin = atan2(s.velocity.y, s.velocity.x);
    } else if (isPumpkin) {
        float seed = s.lump - 2.0;
        o.spin = sin(time * 2.2 + seed * 25.0) * 0.28;
    } else if (isGoldenLeaf) {
        float seed = frac(-s.lump);
        o.spin = time * (seed - 0.5) * 4.2 + seed * 31.0;
    } else if (isLeaf) {
        float seed = -s.lump;
        o.spin = time * (seed - 0.5) * 5.2 + seed * 31.0;
    } else if (isClump) {
        o.spin = time * (s.lump - 0.5) * 9.0 + s.lump * 40.0;
    } else {
        o.spin = 0.0;
    }
    return o;
}

float4 spriteFragment(SpriteOut i) : SV_Target {
    float2 p = float2(i.coord.x - 0.5, 0.5 - i.coord.y);
    bool isSpecialQuad = i.lump >= 3.0 || (i.lump <= -2.5 && i.lump >= -6.5);
    float2 half_ = isSpecialQuad ? float2(0.0, 0.0) : i.streak * 0.5;
    float span = dot(half_, half_);
    float t = span > 0.0 ? clamp(dot(p, half_) / span, -1.0, 1.0) : 0.0;
    float2 d = p - half_ * t;
    float rad = max(i.radius, 0.001);
    float2 u = d / rad;

    // Cursor Tools: Ghost-Vac (-3.0), Magic Swiffer (-4.0), Gust Blower (-5.0), Golden Magnet (-6.0)
    if (i.lump <= -2.5 && i.lump >= -6.5) {
        float c = cos(i.spin), s = sin(i.spin);
        float2 tp = float2(u.x * c + u.y * s, -u.x * s + u.y * c);
        float r = length(u);

        if (i.lump > -3.5) {
            // Ghost-Vac (-3.0): glowing ectoplasm vortex + nozzle
            float swirlAngle = atan2(u.y, u.x) - time * 11.0 + r * 5.5;
            float spiral = pow(saturate(0.5 + 0.5 * sin(swirlAngle * 3.0)), 2.5);
            float vortex = exp(-r * 1.45) * (0.35 + 0.65 * spiral) * (1.0 - smoothstep(0.95, 1.35, r));
            float ring = exp(-abs(r - 0.52) * 9.0) * 0.65 + exp(-abs(r - 0.24) * 12.0) * 0.75;
            bool nozzle = tp.x < -0.15 && tp.x > -0.85 && abs(tp.y) < lerp(0.32, 0.14, saturate((-tp.x - 0.15) / 0.70));
            float nozzleA = nozzle ? 0.92 : 0.0;
            float a = saturate(max(vortex * 0.78 + ring * 0.5, nozzleA)) * i.alpha;
            if (a < 0.003) discard;
            float3 ecto = lerp(float3(0.20, 0.95, 0.85), float3(0.60, 0.35, 1.0), saturate(r * 0.85));
            float3 col = nozzle ? lerp(float3(0.28, 0.30, 0.36), float3(0.45, 0.95, 0.90), exp(-abs(tp.y) * 8.0) * 0.6) : (ecto + float3(0.4, 1.0, 0.9) * ring * 0.6);
            return float4(col * a, a);
        } else if (i.lump > -4.5) {
            // Magic Swiffer / Witch Broom (-4.0)
            float sweepWiggle = 0.12 * sin(time * 14.0);
            float cw = cos(sweepWiggle), sw = sin(sweepWiggle);
            float2 bp = float2(tp.x * cw - tp.y * sw, tp.x * sw + tp.y * cw);
            bool handle = bp.x < 0.05 && bp.x > -1.05 && abs(bp.y) < 0.085;
            bool ferrule = abs(bp.x - 0.05) < 0.07 && abs(bp.y) < 0.20;
            float bristleSpread = lerp(0.16, 0.58, saturate((bp.x - 0.05) / 0.85));
            bool bristles = bp.x >= 0.05 && bp.x < 0.92 && abs(bp.y) < bristleSpread;
            float sparkle = exp(-r * 1.6) * 0.28;
            float a = ((handle || ferrule || bristles) ? 0.94 : sparkle) * i.alpha;
            if (a < 0.003) discard;
            float3 col = float3(1.0, 0.85, 0.35);
            if (ferrule) {
                col = float3(0.98, 0.78, 0.22);
            } else if (handle) {
                col = lerp(float3(0.48, 0.26, 0.11), float3(0.28, 0.14, 0.05), saturate(abs(bp.y) * 10.0));
            } else if (bristles) {
                float strand = sin(bp.y * 38.0 + bp.x * 8.0) * 0.5 + 0.5;
                col = lerp(float3(0.88, 0.64, 0.20), float3(0.58, 0.36, 0.10), strand * 0.65);
                col = lerp(col, float3(1.0, 0.92, 0.55), smoothstep(0.65, 0.92, bp.x) * 0.55);
            }
            return float4(col * a, a);
        } else if (i.lump > -5.5) {
            // Gust Blower (-5.0)
            float wave1 = exp(-abs(r - frac(time * 1.8) * 1.15) * 10.0) * (1.0 - frac(time * 1.8));
            float wave2 = exp(-abs(r - frac(time * 1.8 + 0.5) * 1.15) * 10.0) * (1.0 - frac(time * 1.8 + 0.5));
            float cone = (tp.x > -0.2 && abs(tp.y) < (tp.x + 0.35) * 0.65 && r < 1.2) ? exp(-r * 1.3) * 0.55 : 0.0;
            float a = saturate(wave1 * 0.85 + wave2 * 0.85 + cone) * i.alpha;
            if (a < 0.003) discard;
            float3 col = lerp(float3(0.55, 0.86, 1.0), float3(0.95, 0.98, 1.0), saturate(wave1 + wave2));
            return float4(col * a, a);
        } else {
            // Golden Magnet (-6.0): glowing horseshoe magnet with golden field rings
            float pulse1 = exp(-abs(r - (1.15 - frac(time * 1.4) * 0.95)) * 11.0) * frac(time * 1.4);
            float pulse2 = exp(-abs(r - (1.15 - frac(time * 1.4 + 0.5) * 0.95)) * 11.0) * frac(time * 1.4 + 0.5);
            float2 mp = u * 1.25;
            float archR = length(mp - float2(0.0, 0.10));
            bool inArch = mp.y >= 0.10 && archR > 0.28 && archR < 0.62;
            bool inLegs = mp.y < 0.10 && mp.y > -0.52 && abs(abs(mp.x) - 0.45) < 0.17;
            bool inTips = mp.y < -0.26 && mp.y > -0.52 && abs(abs(mp.x) - 0.45) < 0.17;
            bool inMagnet = inArch || inLegs;
            float fieldGlow = (pulse1 + pulse2) * 0.75 + exp(-r * 1.6) * 0.28;
            float a = saturate(inMagnet ? 0.95 : fieldGlow) * i.alpha;
            if (a < 0.003) discard;
            float3 col = float3(1.0, 0.86, 0.24);
            if (inTips) {
                col = lerp(float3(0.92, 0.94, 0.98), float3(1.0, 0.92, 0.50), 0.35);
            } else if (inMagnet) {
                col = mp.x < 0.0 ? float3(0.96, 0.18, 0.16) : float3(0.20, 0.52, 0.98);
                col = lerp(col, float3(1.0, 0.88, 0.32), 0.22);
            }
            return float4(col * a, a);
        }
    }

    if (i.lump >= 3.0) {
        float side = i.lump > 3.5 ? -1.0 : 1.0;
        float excite = saturate(i.tint.a);
        float c = cos(i.spin * side), s = sin(i.spin * side);
        float2 lp = float2(u.x * c - u.y * s, u.x * s + u.y * c);
        float2 stemP = lp - float2(0.06 * side * sin(lp.y * 4.0), 0.76);
        bool inStem = abs(stemP.x - 0.08 * side * (lp.y - 0.55)) < 0.13 * (1.18 - (lp.y - 0.58)) && lp.y > 0.52 && lp.y < 1.08;

        float2 bodyP = float2(lp.x * 0.82, (lp.y + 0.08) * 1.08);
        float bodyR = length(bodyP);
        float ribWave = cos(lp.x * 6.8);
        bodyR -= 0.055 * ribWave * (1.0 - abs(lp.y) * 0.45);

        float bodyAlpha = 1.0 - smoothstep(0.86, 0.97, bodyR);
        float stemAlpha = inStem ? (1.0 - smoothstep(1.0, 1.08, lp.y)) : 0.0;
        float a = max(bodyAlpha, stemAlpha) * i.alpha;
        float flicker = 0.88 + 0.12 * sin(time * (11.5 + excite * 8.0) + side * 2.0) * cos(time * 17.0);
        float halo = exp(-dot(u, u) * lerp(1.25, 0.90, excite)) * lerp(0.42, 0.68, excite) * i.alpha;
        if (a < 0.002 && halo < 0.002) discard;

        float3 pumpkinBase = lerp(float3(0.98, 0.46, 0.08), float3(0.52, 0.14, 0.02), saturate(bodyR * 0.72 - ribWave * 0.22 - lp.y * 0.18));
        float ex = abs(lp.x) - 0.31;
        float ey = lp.y - 0.14;
        bool inEye = ey > -0.11 && ey < 0.22 && abs(ex) < (0.23 - ey) * 0.82;
        float2 lookOffset = clamp(i.streak, float2(-0.10, -0.07), float2(0.10, 0.07));
        float2 leftEyeCenter = float2(-0.31, 0.02) + lookOffset;
        float2 rightEyeCenter = float2(0.31, 0.02) + lookOffset;
        float pupilDist = min(length(lp - leftEyeCenter), length(lp - rightEyeCenter));
        bool inPupil = inEye && pupilDist < 0.068;

        bool inNose = lp.y > -0.11 && lp.y < 0.04 && abs(lp.x) < (0.05 - lp.y) * 0.75;
        float mx = abs(lp.x);
        float smileCurve = -0.26 + (0.18 + excite * 0.06) * lp.x * lp.x;
        float my = lp.y - smileCurve;
        float tooth = 0.055 * sign(sin(lp.x * 19.0));
        bool inMouth = mx < 0.56 && abs(my - tooth * 0.35) < (0.135 + excite * 0.03) * (1.0 - mx * 1.15);

        float3 col = pumpkinBase;
        if (inStem && bodyAlpha < 0.5) {
            col = float3(0.26, 0.36, 0.13);
        } else if (inPupil) {
            col = float3(1.0, 0.99, 0.88) * 1.45;
        } else if (inEye || inNose || inMouth) {
            float3 innerFlame = lerp(float3(1.0, 0.86, 0.30), float3(1.0, 0.96, 0.65), excite);
            col = innerFlame * ((1.28 + excite * 0.35) * flicker);
        }
        col *= light.rgb;
        float3 haloColor = lerp(float3(1.0, 0.50, 0.12), float3(1.0, 0.78, 0.22), excite);
        float3 premult = col * a + haloColor * halo * (1.0 - a);
        return float4(premult, a + halo * (1.0 - a));
    }

    if (i.lump >= 2.0) {
        float seed = i.lump - 2.0;
        float c = cos(i.spin), s = sin(i.spin);
        float2 lp = float2(u.x * c - u.y * s, u.x * s + u.y * c);
        float2 stemP = lp - float2(0.03 * sin(lp.y * 6.0), 0.78);
        bool inStem = abs(stemP.x) < 0.13 * (1.1 - (lp.y - 0.65)) && lp.y > 0.58 && lp.y < 1.02;

        float2 bodyP = float2(lp.x * 0.88, (lp.y + 0.06) * 1.12);
        float bodyR = length(bodyP);
        float ribWave = cos(lp.x * 7.5);
        bodyR -= 0.05 * ribWave * (1.0 - abs(lp.y) * 0.5);

        float bodyAlpha = 1.0 - smoothstep(0.84, 0.98, bodyR);
        float stemAlpha = inStem ? 1.0 : 0.0;
        float a = max(bodyAlpha, stemAlpha) * i.alpha;
        float halo = exp(-dot(u, u) * 1.6) * 0.38 * i.alpha;
        if (a < 0.003 && halo < 0.003) discard;

        float flicker = 0.86 + 0.14 * sin(time * 13.0 + seed * 47.0);
        float3 candleColor = float3(1.0, 0.86, 0.32) * flicker;
        float3 pumpkinBase = lerp(float3(0.95, 0.42, 0.07), float3(0.58, 0.19, 0.03), saturate(bodyR * 0.75 - ribWave * 0.18));

        float ex = abs(lp.x) - 0.28;
        float ey = lp.y - 0.12;
        bool eye = ey > -0.10 && ey < 0.18 && abs(ex) < (0.18 - ey) * 0.75;
        float mx = abs(lp.x);
        float my = lp.y + 0.22 + 0.07 * cos(lp.x * 5.0);
        bool mouth = mx < 0.46 && abs(my) < 0.11 * (1.0 - mx * 1.4);

        float3 col = pumpkinBase;
        if (inStem && bodyAlpha < 0.5) {
            col = float3(0.26, 0.34, 0.14);
        } else if (eye || mouth) {
            col = candleColor * 1.25;
        }
        col *= light.rgb;
        float3 premult = col * a + float3(1.0, 0.48, 0.10) * halo * (1.0 - a);
        return float4(premult, a + halo * (1.0 - a));
    }

    if (i.lump < -1.0) {
        bool isBloodMoon = i.lump <= -2.0;
        float seed = frac(-i.lump);
        float c = cos(i.spin), s = sin(i.spin);
        float2 lp = float2(u.x * c - u.y * s, u.x * s + u.y * c);
        float tilt = 0.64 + 0.36 * abs(cos(i.spin * 0.65 + seed * 12.0));
        lp.y /= tilt;

        float angle = atan2(lp.y, lp.x);
        float lobes = 1.0 + 0.26 * cos(3.0 * angle) + 0.14 * cos(5.0 * angle);
        float r = length(lp * float2(0.84, 1.10)) / max(lobes, 0.35);

        float leafAlpha = (1.0 - smoothstep(0.68, 1.0, r)) * i.alpha;
        float sparklePulse = 0.82 + 0.18 * sin(time * 10.5 + seed * 40.0);

        float flareAngle = time * 1.8 + seed * 15.0;
        float fc = cos(flareAngle), fs = sin(flareAngle);
        float2 fu = float2(u.x * fc - u.y * fs, u.x * fs + u.y * fc);
        float starRay = (exp(-abs(fu.x) * 6.5) * exp(-abs(fu.y) * 1.35) + exp(-abs(fu.y) * 6.5) * exp(-abs(fu.x) * 1.35)) * 0.62 * sparklePulse;
        float ringGlow = exp(-abs(length(u) - (0.92 + 0.10 * sin(time * 5.0 + seed * 9.0))) * 9.5) * 0.42 * sparklePulse;
        float aura = saturate(exp(-dot(u, u) * 0.95) * 0.64 * sparklePulse + starRay + ringGlow) * i.alpha;
        if (leafAlpha < 0.002 && aura < 0.002) discard;

        float vein = exp(-abs(lp.x + 0.07 * sin(lp.y * 4.0)) * 9.0) * saturate(1.0 - r);
        float glintWave = pow(saturate(0.5 + 0.5 * sin(time * 6.4 + (lp.x * 3.8 + lp.y * 2.6) + seed * 20.0)), 4.0);
        float3 goldBase = isBloodMoon
            ? lerp(float3(1.0, 0.22, 0.18), float3(1.0, 0.78, 0.16), smoothstep(0.15, 0.90, r))
            : lerp(float3(1.0, 0.90, 0.24), float3(0.96, 0.62, 0.06), smoothstep(0.20, 0.95, r));
        float3 goldSpec = float3(1.0, 0.99, 0.88);
        float3 color = lerp(goldBase, goldSpec, saturate(glintWave * 0.82 + vein * 0.65));
        float3 auraTint = isBloodMoon ? float3(1.0, 0.38, 0.22) : float3(1.0, 0.88, 0.26);
        float3 premult = color * leafAlpha + lerp(auraTint, goldSpec, saturate(starRay)) * aura * (1.0 - leafAlpha * 0.65);
        return float4(premult, saturate(leafAlpha + aura * (1.0 - leafAlpha)));
    }

    if (i.lump < 0.0) {
        float seed = -i.lump;
        float c = cos(i.spin), s = sin(i.spin);
        float2 lp = float2(u.x * c - u.y * s, u.x * s + u.y * c);
        float tilt = 0.52 + 0.48 * abs(cos(i.spin * 0.65 + seed * 12.0));
        lp.y /= tilt;

        float angle = atan2(lp.y, lp.x);
        float lobes = seed > 0.5
            ? 1.0 + 0.22 * cos(3.0 * angle) + 0.10 * cos(5.0 * angle)
            : 1.0 + 0.28 * cos(2.0 * angle) - 0.08 * cos(4.0 * angle);
        float r = length(lp * float2(0.85, 1.15)) / max(lobes, 0.35);

        float a = (1.0 - smoothstep(0.68, 1.0, r)) * i.alpha;
        if (a < 0.002) discard;

        float vein = exp(-abs(lp.x + 0.08 * sin(lp.y * 4.0)) * 9.0) * saturate(1.0 - r);
        float3 baseTint = i.tint.rgb;
        float3 rimTint = baseTint * float3(0.55, 0.42, 0.32);
        float3 veinTint = min(baseTint * 1.28 + float3(0.12, 0.08, 0.02), float3(1.0, 1.0, 1.0));
        float3 color = lerp(baseTint, rimTint, smoothstep(0.3, 0.95, r));
        color = lerp(color, veinTint, vein * 0.45) * light.rgb;
        return float4(color * a, a);
    }

    float r = length(d) / rad;
    float shading = 0.0;
    if (i.lump > 0.0) {
        float angle = atan2(d.y, d.x) + i.spin;
        r /= 1.0 + 0.16 * sin(3.0 * angle) + 0.10 * sin(5.0 * angle + i.lump * 21.0) + 0.06 * sin(2.0 * angle + i.lump * 9.0);
        shading = saturate(dot(u, float2(0.45, -0.6))) * 0.45;
    }
    float head = span > 0.0 ? 0.15 + 0.85 * pow(t * 0.5 + 0.5, 1.5) : 1.0;
    float a = (1.0 - smoothstep(lerp(0.55, 0.0, i.soft), 1.0, r)) * i.alpha * head;
    if (a < 0.002) discard;
    float3 baseColor = lerp(float3(1.0, 0.55, 0.14), i.tint.rgb, i.tint.a);
    float3 core = min(baseColor * 1.35 + float3(0.22, 0.16, 0.06), float3(1.0, 1.0, 1.0));
    float3 rim = baseColor * 0.52;
    float3 color = lerp(core, rim, saturate(smoothstep(0.25, 1.0, r) * 0.7 + shading)) * light.rgb;
    return float4(color * a, a);
}

struct PileOut {
    float4 position : SV_Position;
    float2 local : TEXCOORD0;
};

PileOut pileVertex(uint vid : SV_VertexID) {
    float2 corner = float2(float(vid & 1), float(vid >> 1));
    float2 p = float2(corner.x * float(columnCount) * columnWidth, lerp(pileBottom, pileTop, corner.y));
    PileOut o;
    o.position = float4((p + origin) / viewSize * 2.0 - 1.0, 0.0, 1.0);
    o.local = p;
    return o;
}

float heightAt(int start, float x) {
    float f = x / columnWidth - 0.5;
    float base = floor(f);
    int i = clamp(int(base), 0, columnCount - 1);
    int j = min(i + 1, columnCount - 1);
    return lerp(heights[start + i], heights[start + j], saturate(f - base));
}

float4 pileFragment(PileOut i) : SV_Target {
    float2 world = i.local + origin;
    [loop]
    for (int k = 0; k < occluderCount; k++) {
        float4 o = occluders[k];
        if (world.x >= o.x && world.x < o.z && world.y >= o.y && world.y < o.w) discard;
    }

    float x = i.local.x;
    float level = heightAt(heightOffset, x);
    float bed = heightAt(heightOffset + columnCount, x);
    float depth = level - i.local.y;
    float coverage = saturate(depth * scale + 0.5)
        * saturate((i.local.y - bed) * scale + 0.5)
        * saturate((level - bed) / 0.75);
    if (coverage <= 0.0) discard;

    float slope = (heightAt(heightOffset, x + 2.0) - heightAt(heightOffset, x - 2.0)) * 0.25;
    float lit = dot(normalize(float2(-slope, 1.0)), normalize(float2(-0.5, 1.0)));

    float2 leafCell = floor(float2(world.x * 0.22 + sin(world.y * 0.3) * 0.6, world.y * 0.32));
    float leafPick = hash(leafCell);
    float3 leafA = float3(0.82, 0.33, 0.08);
    float3 leafB = float3(0.64, 0.15, 0.10);
    float3 leafC = float3(0.88, 0.55, 0.12);
    float3 leafD = float3(0.42, 0.20, 0.11);
    float3 leafColor = leafPick < 0.32 ? leafA : (leafPick < 0.60 ? leafB : (leafPick < 0.82 ? leafC : leafD));

    float3 shadow = lerp(float3(0.18, 0.09, 0.12), shadowTint.rgb * 0.45, shadowTint.a);
    float3 surface = lerp(leafColor, min(shadowTint.rgb * 1.1, float3(1.0, 1.0, 1.0)), shadowTint.a * 0.12);
    float shade = (1.0 - exp(-depth / 22.0)) * 0.55 + (1.0 - lit) * 0.45 * exp(-depth / 6.0);
    float3 color = lerp(surface, shadow, saturate(shade));
    color = lerp(color, float3(0.98, 0.64, 0.20), exp(-max(depth, 0.0) * 0.85) * 0.38);
    color += (hash(floor(i.position.xy)) - 0.5) * 0.03;

    float seed = hash(floor(i.position.xy * 0.35) + 31.7);
    if (seed > 0.984) {
        float twinkle = 0.45 + 0.55 * pow(saturate(sin(time * (1.2 + seed * 2.4) + seed * 90.0)), 4.0);
        color = lerp(color, float3(1.0, 0.52, 0.12), twinkle * exp(-depth / 12.0));
    }

    color *= light.rgb;
    if (lantern.z > 0.5) {
        float dist = length(world - lantern.xy);
        float glow = exp(-dist * dist / (190.0 * 190.0)) * lantern.w;
        color += float3(1.0, 0.52, 0.12) * glow * 0.55;
    }
    return float4(min(color, float3(1.0, 1.0, 1.0)) * coverage, coverage);
}
