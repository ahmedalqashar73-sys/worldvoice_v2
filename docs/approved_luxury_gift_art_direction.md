# WorldVoice gift art direction — approved reference, 2026-09-30

## Decision
The user rejected the existing simple procedural 3D models and SVGs as final visuals. Keep the existing 30 `classic_*` gift IDs, names, prices, sorting, economy checks, no-self-gifting rule, chat/room/live routing and animations. Replace **art**, not economy semantics. Do not generate any new pictures without another explicit request.

## Exact reference art
The user supplied three reference screenshots in chat:
- Luminous butterfly: pale turquoise/teal, translucent layered wings, delicately filigreed metallic-gold veins, rich glass-like highlights.
- Golden phoenix: intricate fiery sculpted plumage, glowing copper/orange/gold material, impressive wingspan and tail.
- Royal rose: deep burgundy/red velvet petals, sculpted polished gold stem and leaves.

The user also approved the previously rendered high-resolution reference stills in the conversation as visual direction; **they are not true turntable meshes**. Preserve fidelity to the user's supplied screenshots, not the current stylized geometry.

## Implementation contract
1. Replace or upgrade art for **all 30** existing gift IDs with the same cohesive photorealistic collectible style, consistent scale and studio lighting. Do not rename, duplicate, reprice, enable paid gifts or alter the JSON catalog schema without compatibility checks.
2. For the three hero gifts (classic_luminous_butterfly, classic_golden_phoenix, classic_royal_rose), match their approved reference first; use them as the material and rendering standard for the other 27.
3. Provide optimized **real 3D glTF/GLB** with physically based metallic/roughness materials if true interactive 3D is advertised. Rendered PNG/WebP images alone must be labeled as rendered art, not meshes. Provide a high-quality 2D preview and accessible fallback for older devices.
4. Remove studio background cleanly from preview renders (transparent asset), preserving delicate edges. Never show white screenshot rectangles in the green gift picker.
5. Keep premium emerald-and-gold, borderless catalog tiles; name and coin count remain under art. Animated in-room effects must fit within safe bounds and show verified sender and recipient names. Do not obscure microphone controls or seats.
6. Preserve the no-self-gift constraint in both the Flutter selector and trusted backend. Free friend demos must be explicitly marked, not written to the paid gift ledger, and must not change coin or diamond balances.
7. Asset production is a separate pending deliverable: this document does NOT assert that 30 high-fidelity GLBs have been produced or that the three reference renders are integrated. Do not call the current stylized models final.
8. Run `flutter analyze`, widget tests, model validation and Android test build before sending a test APK to friends.

## Gift art palette
Deep emerald #073D32, antique gold #D6B56C, burgundy #650D25, translucent teal #7DCED0, flame copper #E76D20. Material realism and detailing are more important than increasing polygon count. 
