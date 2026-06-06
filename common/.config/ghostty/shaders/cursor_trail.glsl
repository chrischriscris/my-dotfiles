void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float baseProgress = clamp((iTime - iTimeCursorChange) / 0.3, 0.0, 1.0);
    
    vec2 uv = fragCoord / iResolution.xy;
    vec4 background = texture(iChannel0, uv);
    
    if (baseProgress >= 1.0) {
        fragColor = background;
        return;
    }
    
    fragColor = background;
    
    float invResY = 1.0 / iResolution.y;
    float scale = 2.0 * invResY;
    float aaWidth = scale;
    vec2 normOffset = iResolution.xy * invResY;
    
    vec2 currentPos = iCurrentCursor.xy * scale - normOffset;
    vec2 previousPos = iPreviousCursor.xy * scale - normOffset;
    vec2 currentSize = iCurrentCursor.zw * scale;
    vec2 previousSize = iPreviousCursor.zw * scale;
    
    vec2 deltaPos = currentPos - previousPos;
    vec2 selector = step(vec2(0.0), deltaPos);
    
    vec2 normCoord = fragCoord * scale - normOffset;
    
    vec2 p1 = selector.x == 0.0 ? 
              (selector.y == 0.0 ? currentPos + vec2(currentSize.x, 0.0) : currentPos) :
              (selector.y == 0.0 ? currentPos : currentPos + vec2(currentSize.x, -currentSize.y));
    
    vec2 p2 = selector.x == 0.0 ?
              (selector.y == 0.0 ? previousPos + vec2(previousSize.x, 0.0) : previousPos + vec2(previousSize.x, -previousSize.y)) :
              (selector.y == 0.0 ? previousPos : previousPos + vec2(0.0, -previousSize.y));
    
    vec2 p3 = selector.x == 0.0 ?
              (selector.y == 0.0 ? previousPos : previousPos + vec2(0.0, -previousSize.y)) :
              (selector.y == 0.0 ? previousPos + vec2(previousSize.x, 0.0) : previousPos + vec2(previousSize.x, -previousSize.y));
    
    vec2 p4 = selector.x == 0.0 ?
              (selector.y == 0.0 ? previousPos + vec2(0.0, -previousSize.y) : previousPos) :
              (selector.y == 0.0 ? previousPos + vec2(previousSize.x, -previousSize.y) : previousPos + vec2(previousSize.x, 0.0));
    
    float easedProgress = 1.0 - pow(1.0 - baseProgress, 3.0);
    float stretchedProgress = min(baseProgress * 2.0, 1.0);
    float easedProgressDouble = 1.0 - pow(1.0 - stretchedProgress, 3.0);
    
    vec2 trailP2 = mix(p2, p1, easedProgressDouble);
    vec2 trailP3 = mix(p3, p1, easedProgressDouble);
    vec2 trailP4 = mix(p4, mix(p1, currentPos + vec2(currentSize.x * 0.5, -currentSize.y * 0.5), easedProgress), easedProgress);
    
    vec2 v0 = p1;
    vec2 v1 = trailP2;
    vec2 v2 = trailP3;
    vec2 v3 = trailP4;
    vec2 v4 = currentPos + vec2(currentSize.x, -currentSize.y);
    vec2 v5 = currentPos + vec2(currentSize.x, 0.0);
    
    float minDist = 1e20;
    float inside = 1.0;
    
    vec2 edges[6] = {v0, v1, v2, v3, v4, v5};
    for (int i = 0; i < 6; i++) {
        vec2 a = edges[i];
        vec2 b = edges[(i + 1) % 6];
        vec2 edge = b - a;
        vec2 pa = normCoord - a;
        float lenSq = dot(edge, edge);
        if (lenSq > 0.0) {
            float t = clamp(dot(pa, edge) / lenSq, 0.0, 1.0);
            vec2 diff = pa - edge * t;
            minDist = min(minDist, dot(diff, diff));
            float cross = edge.x * pa.y - edge.y * pa.x;
            inside = min(inside, step(0.0, cross));
        }
    }
    
    float dist = sqrt(max(minDist, 0.0));
    float sdf = mix(dist, -dist, inside);
    float alpha = 1.0 - smoothstep(-aaWidth, aaWidth, sdf);
    
    vec2 halfCurrentSize = currentSize * 0.5;
    vec2 currentCenter = currentPos + vec2(halfCurrentSize.x, -halfCurrentSize.y);
    vec2 d = abs(normCoord - currentCenter) - halfCurrentSize;
    float sdfCurrent = length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
    
    vec4 originalColor = fragColor;
    fragColor.rgb = mix(fragColor.rgb, iCurrentCursorColor.rgb, alpha * 0.6);
    fragColor.rgb = mix(fragColor.rgb, originalColor.rgb, step(sdfCurrent, 0.0));
}