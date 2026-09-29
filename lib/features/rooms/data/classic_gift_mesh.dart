import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

/// Actual glTF 2.0 triangle meshes, generated on demand for each of the
/// thirty approved Classic gifts. These are original *stylized low-poly*
/// models (not photorealistic 3D scans), with metallic PBR materials.
/// No network models, unlicensed third-party assets or unreviewed downloads.
class ClassicGiftMesh {
  ClassicGiftMesh._();

  static final Map<String, String> _cache = {};

  static String dataUri(String id) =>
      _cache.putIfAbsent(id, () => 'data:model/gltf-binary;base64,'
          '${base64Encode(_GiftBuilder().._model(id))}');

  // Keep a raw binary entry point for deterministic schema validation.
  static Uint8List binary(String id) {
    final builder = _GiftBuilder().._model(id);
    return builder.encode();
  }

  static bool supports(String id) => const {
    'classic_soft_rose', 'classic_green_heart',
    'classic_glowing_star', 'classic_love_candle',
    'classic_royal_rose', 'classic_luxury_balloon', 'classic_coffee',
    'classic_pearl_crescent', 'classic_golden_feather',
    'classic_small_present', 'classic_mini_crown',
    'classic_green_diamond', 'classic_glossy_strawberry',
    'classic_royal_star', 'classic_luxe_perfume',
    'classic_love_necklace', 'classic_love_letter',
    'classic_sea_pearl', 'classic_luminous_butterfly',
    'classic_golden_heart', 'classic_white_swan', 'classic_orchid',
    'classic_celebration_cake', 'classic_lovebird',
    'classic_diamond_ring', 'classic_star_moon',
    'classic_graceful_deer', 'classic_luxury_bouquet',
    'classic_baby_peacock', 'classic_golden_phoenix',
  }.contains(id);
}

class _GiftBuilder {
  static const _colors = <List<double>>[
    [.95, .69, .21], // 0: royal metallic gold
    [.04, .54, .34], // 1: emerald
    [.81, .035, .12], // 2: crimson rose
    [.93, .32, .48], // 3: rose pink
    [.91, .93, .91], // 4: pearl
    [.09, .42, .89], // 5: sapphire butterfly
    [1, .32, .025], // 6: golden fire
    [.19, .16, .17], // 7: charcoal
    [.48, .27, .12], // 8: warm brown
    [.13, .78, .52], // 9: jade
    [.99, .76, .41], // 10: light gold
    [.53, .18, .70], // 11: orchid
  ];
  final _faces = List.generate(
      _colors.length, (_) => <(List<double>, List<double>, List<double>, List<double>)>[]);

  List<double> _v(double x, double y, double z) => [x, y, z];
  void _triangle(int m, List<double> a, List<double> b, List<double> c) {
    final u = List<double>.generate(3, (i) => b[i] - a[i]);
    final v = List<double>.generate(3, (i) => c[i] - a[i]);
    final n = [
      u[1] * v[2] - u[2] * v[1],
      u[2] * v[0] - u[0] * v[2],
      u[0] * v[1] - u[1] * v[0],
    ];
    final len = math.sqrt(n.fold<double>(0, (s, x) => s + x * x));
    _faces[m].add((a, b, c,
        n.map((x) => len > 1e-7 ? x / len : 0.0).toList()));
  }

  void _quad(int m, List<double> a, List<double> b,
      List<double> c, List<double> d) {
    _triangle(m, a, b, c);
    _triangle(m, a, c, d);
  }

  void _orb(int m, double x, double y, double z,
      double rx, double ry, double rz) {
    List<double> point(double a, double p) => _v(
        x + rx * math.cos(a) * math.sin(p),
        y + ry * math.cos(p),
        z + rz * math.sin(a) * math.sin(p));
    for (var j = 0; j < 5; j++) {
      for (var i = 0; i < 9; i++) {
        final a = i * 2 * math.pi / 9;
        final b = (i + 1) * 2 * math.pi / 9;
        final p = j * math.pi / 5;
        final q = (j + 1) * math.pi / 5;
        _quad(m, point(a, p), point(b, p), point(b, q), point(a, q));
      }
    }
  }

  void _cylinder(int m, double x, double y, double z,
      double r, double h) {
    for (var i = 0; i < 10; i++) {
      final a = i * 2 * math.pi / 10;
      final b = (i + 1) * 2 * math.pi / 10;
      final lo = y - h / 2, hi = y + h / 2;
      final p = _v(x + r * math.cos(a), lo, z + r * math.sin(a));
      final q = _v(x + r * math.cos(b), lo, z + r * math.sin(b));
      final t = _v(x + r * math.cos(a), hi, z + r * math.sin(a));
      final u = _v(x + r * math.cos(b), hi, z + r * math.sin(b));
      _quad(m, p, q, u, t);
      _triangle(m, _v(x, hi, z), t, u);
    }
  }

  void _badge(int m, List<List<double>> vertices, [double depth = .10]) {
    final cx = vertices.map((v) => v[0]).reduce((a, b) => a + b) /
        vertices.length;
    final cy = vertices.map((v) => v[1]).reduce((a, b) => a + b) /
        vertices.length;
    for (var i = 0; i < vertices.length; i++) {
      final a = vertices[i], b = vertices[(i + 1) % vertices.length];
      _triangle(m, _v(cx, cy, depth),
          _v(a[0], a[1], depth), _v(b[0], b[1], depth));
      _triangle(m, _v(cx, cy, -depth),
          _v(b[0], b[1], -depth), _v(a[0], a[1], -depth));
      _quad(m, _v(a[0], a[1], -depth),
          _v(b[0], b[1], -depth),
          _v(b[0], b[1], depth), _v(a[0], a[1], depth));
    }
  }

  void _heart(int color) {
    final pts = <List<double>>[];
    for (var i = 0; i < 26; i++) {
      final t = i * 2 * math.pi / 26;
      pts.add([
        .035 * 16 * math.pow(math.sin(t), 3).toDouble(),
        .035 * (13 * math.cos(t) - 5 * math.cos(2 * t) -
            2 * math.cos(3 * t) - math.cos(4 * t)),
      ]);
    }
    _badge(color, pts, .15);
  }

  void _star(int color) {
    _badge(color, [
      for (var i = 0; i < 10; i++)
        [
          (i.isOdd ? .28 : .63) *
              math.cos(math.pi / 2 + i * math.pi / 5),
          (i.isOdd ? .28 : .63) *
              math.sin(math.pi / 2 + i * math.pi / 5),
        ]
    ]);
  }

  void _leaf(int m, double x, double y, double z,
      double angle, double length, double width) {
    final co = math.cos(angle), si = math.sin(angle);
    final a = _v(x, y, z);
    final tip = _v(x + length * co, y + length * si, z + .08);
    final left = _v(x + .52 * length * co - width * si,
        y + .52 * length * si + width * co, z + .13);
    final right = _v(x + .52 * length * co + width * si,
        y + .52 * length * si - width * co, z + .13);
    _quad(m, a, left, tip, right);
  }

  void _rose({double x = 0, double y = 0, double z = 0,
      double scale = 1, int color = 2}) {
    _cylinder(1, x, y - .28 * scale, z, .035 * scale, .65 * scale);
    _orb(1, x - .16 * scale, y - .43 * scale, z,
        .22 * scale, .07 * scale, .13 * scale);
    _orb(0, x, y + .19 * scale, z,
        .16 * scale, .14 * scale, .15 * scale);
    for (var i = 0; i < 9; i++) {
      final a = i * 2 * math.pi / 9;
      final r = (.13 + .038 * (i % 2)) * scale;
      _orb(color, x + r * math.cos(a),
          y + (.24 + .035 * (i % 3)) * scale,
          z + r * math.sin(a),
          .17 * scale, .21 * scale, .12 * scale);
    }
    _orb(color, x, y + .32 * scale, z,
        .14 * scale, .19 * scale, .14 * scale);
  }

  void _bird(int color) {
    _orb(color, 0, -.12, 0, .30, .32, .23);
    _orb(color, 0, .23, .02, .12, .29, .13);
    _orb(color, 0, .49, .06, .16, .15, .14);
    _orb(0, 0, .46, .2, .07, .06, .08);
  }

  void _wings(int primary, int accent) {
    for (final s in [-1.0, 1.0]) {
      _badge(primary, [[0, .12], [s * .3, .64],
        [s * .81, .46], [s * .52, .04]], .035);
      _badge(accent, [[0, .0], [s * .36, -.06],
        [s * .68, -.49], [s * .19, -.36]], .035);
    }
  }

  void _boxGift() {
    _orb(2, 0, 0, 0, .43, .40, .36);
    _cylinder(0, 0, 0, .32, .07, .68);
    _orb(0, -.18, .46, 0, .19, .10, .12);
    _orb(0, .18, .46, 0, .19, .10, .12);
  }

  void _model(String id) {
    if (!ClassicGiftMesh.supports(id)) {
      throw ArgumentError.value(id, 'id', 'Unapproved gift model');
    }
    switch (id) {
      case 'classic_soft_rose':
        _rose(scale: .92, color: 3);
      case 'classic_royal_rose':
        _rose(scale: 1.12);
      case 'classic_orchid':
        _rose(color: 11);
      case 'classic_luxury_bouquet':
        for (var j = 0; j < 3; j++) {
          final a = j * 2 * math.pi / 3;
          _rose(x: .22 * math.cos(a),
              z: .22 * math.sin(a), scale: .65, color: j.isOdd ? 3 : 2);
        }
      case 'classic_green_heart':
        _heart(9);
      case 'classic_golden_heart':
        _heart(0);
      case 'classic_glowing_star':
      case 'classic_royal_star':
        _star(0);
      case 'classic_star_moon':
        _star(4);
        _orb(0, .32, -.31, 0, .18, .19, .10);
      case 'classic_love_candle':
        _cylinder(4, 0, -.25, 0, .28, .62);
        _orb(6, 0, .25, 0, .10, .19, .09);
      case 'classic_luxury_balloon':
        _orb(2, 0, .18, 0, .38, .54, .31);
        _cylinder(0, 0, -.49, 0, .013, .41);
      case 'classic_coffee':
        _cylinder(4, 0, -.12, 0, .36, .50);
        _orb(8, 0, .16, 0, .31, .03, .31);
        _orb(0, .40, -.04, 0, .10, .22, .18);
      case 'classic_pearl_crescent':
        _badge(4, [
          for (var i = 0; i <= 13; i++)
            [.05 + .64 * math.cos(-2 + 4 * i / 13),
             .64 * math.sin(-2 + 4 * i / 13)],
          for (var i = 13; i >= 0; i--)
            [.24 + .37 * math.cos(-2 + 4 * i / 13),
             .37 * math.sin(-2 + 4 * i / 13)],
        ]);
      case 'classic_golden_feather':
        _leaf(0, -.42, -.39, 0, .76, 1.13, .17);
      case 'classic_small_present':
      case 'classic_love_letter':
        _boxGift();
      case 'classic_mini_crown':
        _cylinder(0, 0, -.26, 0, .44, .28);
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          _orb(0, .34 * math.cos(a),
              .20, .34 * math.sin(a), .12, .25, .12);
        }
      case 'classic_green_diamond':
        _orb(9, 0, 0, 0, .43, .58, .36);
        _orb(0, 0, -.46, 0, .39, .08, .35);
      case 'classic_glossy_strawberry':
        _orb(2, 0, -.08, 0, .34, .45, .32);
        for (var i = 0; i < 5; i++) {
          _leaf(1, 0, .33, 0, i * 2 * math.pi / 5, .3, .08);
        }
      case 'classic_luxe_perfume':
        _orb(4, 0, -.20, 0, .4, .4, .24);
        _cylinder(0, 0, .27, 0, .12, .29);
      case 'classic_love_necklace':
        _heart(3);
        _orb(0, 0, .49, 0, .15, .10, .12);
      case 'classic_sea_pearl':
        _orb(4, 0, -.29, 0, .46, .11, .33);
        _orb(4, 0, .19, -.17, .46, .11, .3);
        _orb(4, 0, .02, .02, .26, .25, .24);
      case 'classic_luminous_butterfly':
        _cylinder(0, 0, 0, 0, .045, .69);
        _wings(5, 11);
      case 'classic_white_swan':
        _bird(4);
      case 'classic_celebration_cake':
        _cylinder(4, 0, -.24, 0, .44, .45);
        _cylinder(3, 0, .09, 0, .35, .24);
        _orb(6, 0, .43, 0, .07, .13, .07);
      case 'classic_lovebird':
        _bird(3);
      case 'classic_diamond_ring':
        _orb(0, 0, -.32, 0, .4, .13, .31);
        _orb(5, 0, .27, 0, .28, .30, .25);
      case 'classic_graceful_deer':
        _orb(8, 0, -.20, 0, .4, .22, .21);
        _cylinder(8, .22, .05, 0, .10, .42);
        _orb(8, .24, .35, 0, .15, .16, .15);
        for (final s in [-1.0, 1.0]) {
          _cylinder(8, s * .25, -.46, s * .12, .04, .39);
          _leaf(0, .22 + s * .09, .48, 0,
              s > 0 ? .60 : 2.54, .42, .05);
        }
      case 'classic_baby_peacock':
        _bird(5);
        for (var i = 0; i < 7; i++) {
          _leaf(i.isOdd ? 9 : 5, 0, -.1, -.12,
              math.pi / 2 + (i - 3) * .23, .72, .08);
        }
      case 'classic_golden_phoenix':
        _bird(0);
        for (final s in [-1.0, 1.0]) {
          for (var i = 0; i < 5; i++) {
            _leaf(i.isOdd ? 6 : 0, s * .18, -.04, -.09,
                math.pi / 2 + s * i * .20, .64, .12);
          }
        }
    }
  }

  Uint8List encode() {
    final parts = <Uint8List>[];
    final views = <Map<String, Object>>[];
    final accessors = <Map<String, Object>>[];
    final primitives = <Map<String, Object>>[];
    var offset = 0;

    int append(Uint8List bytes, int target) {
      final padded = Uint8List((bytes.length + 3) & ~3);
      padded.setRange(0, bytes.length, bytes);
      final view = views.length;
      views.add({
        'buffer': 0,
        'byteOffset': offset,
        'byteLength': bytes.length,
        'target': target,
      });
      parts.add(padded);
      offset += padded.length;
      return view;
    }

    for (var material = 0; material < _faces.length; material++) {
      final faces = _faces[material];
      if (faces.isEmpty) continue;
      final positions = ByteData(faces.length * 9 * 4);
      final normals = ByteData(faces.length * 9 * 4);
      final indices = ByteData(faces.length * 3 * 2);
      final low = [10.0, 10.0, 10.0];
      final high = [-10.0, -10.0, -10.0];
      var vertex = 0;
      for (final f in faces) {
        for (final point in [f.$1, f.$2, f.$3]) {
          for (var k = 0; k < 3; k++) {
            final value = point[k];
            positions.setFloat32((vertex * 3 + k) * 4,
                value, Endian.little);
            normals.setFloat32((vertex * 3 + k) * 4,
                f.$4[k], Endian.little);
            low[k] = math.min(low[k], value);
            high[k] = math.max(high[k], value);
          }
          indices.setUint16(vertex * 2, vertex, Endian.little);
          vertex++;
        }
      }
      final pv = append(positions.buffer.asUint8List(), 34962);
      final nv = append(normals.buffer.asUint8List(), 34962);
      final iv = append(indices.buffer.asUint8List(), 34963);
      final p = accessors.length;
      accessors.add({
        'bufferView': pv, 'componentType': 5126,
        'count': vertex, 'type': 'VEC3', 'min': low, 'max': high,
      });
      final n = accessors.length;
      accessors.add({
        'bufferView': nv, 'componentType': 5126,
        'count': vertex, 'type': 'VEC3',
      });
      final i = accessors.length;
      accessors.add({
        'bufferView': iv, 'componentType': 5123,
        'count': vertex, 'type': 'SCALAR',
      });
      primitives.add({
        'attributes': {'POSITION': p, 'NORMAL': n},
        'indices': i, 'material': material,
      });
    }
    if (primitives.isEmpty) throw StateError('Gift model has no geometry');

    final meshJson = jsonEncode({
      'asset': {'version': '2.0',
          'generator': 'WorldVoice original low-poly 3D gifts'},
      'scene': 0,
      'scenes': [{'nodes': [0]}],
      'nodes': [{'mesh': 0}],
      'meshes': [{'primitives': primitives}],
      'materials': [
        for (var k = 0; k < _colors.length; k++)
          {
            'doubleSided': true,
            'pbrMetallicRoughness': {
              'baseColorFactor': [..._colors[k], 1.0],
              'metallicFactor': k == 0 ? .76 : .22,
              'roughnessFactor': .33,
            }
          },
      ],
      'buffers': [{'byteLength': offset}],
      'bufferViews': views,
      'accessors': accessors,
    });
    final json = utf8.encode(meshJson);
    final jsonChunk = Uint8List((json.length + 3) & ~3);
    jsonChunk.fillRange(0, jsonChunk.length, 0x20);
    jsonChunk.setRange(0, json.length, json);
    final glb = ByteData(12 + 8 + jsonChunk.length + 8 + offset);
    var at = 0;
    void word(int value) {
      glb.setUint32(at, value, Endian.little);
      at += 4;
    }
    word(0x46546C67); // glTF magic
    word(2);
    word(glb.lengthInBytes);
    word(jsonChunk.length);
    word(0x4E4F534A); // JSON
    glb.buffer.asUint8List().setRange(at, at + jsonChunk.length, jsonChunk);
    at += jsonChunk.length;
    word(offset);
    word(0x004E4942); // BIN
    for (final bytes in parts) {
      glb.buffer.asUint8List().setRange(at, at + bytes.length, bytes);
      at += bytes.length;
    }
    return glb.buffer.asUint8List();
  }
}
