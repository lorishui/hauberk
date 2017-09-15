import 'dart:html' as html;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import 'package:hauberk/src/content.dart';
import 'package:hauberk/src/engine.dart';

import 'histogram.dart';

html.CanvasElement canvas;

var content = createContent();
var heroClass = new Warrior();
var save = new HeroSave("Hero", heroClass);

int get depth {
  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  return int.parse(depthSelect.value);
}

main() {
  canvas = html.querySelector("canvas") as html.CanvasElement;

  var depthSelect = html.querySelector("#depth") as html.SelectElement;
  for (var i = 1; i <= Option.maxDepth; i++) {
    depthSelect.append(
      new html.OptionElement(data: i.toString(), value: i.toString(),
          selected: i == 1));
  }

  depthSelect.onChange.listen((event) {
    generate();
  });

  canvas.onClick.listen((_) {
    generate();
  });

  generate();
}

void generate() {
  var game = new Game(content, save, depth);

  var stage = game.stage;

//  var terminal = new RetroTerminal(stage.width, stage.height, "font_16.png",
//      canvas: canvas, charWidth: 16, charHeight: 16);
  var terminal = new RetroTerminal(stage.width, stage.height, "font_8.png",
      canvas: canvas, charWidth: 8, charHeight: 8);

  for (var y = 0; y < stage.height; y++) {
    for (var x = 0; x < stage.width; x++) {
      var glyph = stage.get(x, y).type.appearance[0] as Glyph;
      terminal.drawGlyph(x, y, glyph);

      var pos = new Vec(x, y);
      var items = stage.itemsAt(pos);
      if (items.isNotEmpty) {
        terminal.drawGlyph(x, y, items.first.appearance as Glyph);
      }

      var actor = stage.actorAt(pos);
      if (actor != null) {
        if (actor.appearance is String) {
          terminal.drawChar(x, y, CharCode.blackSmilingFace, Color.white);
        } else {
          terminal.drawGlyph(x, y, actor.appearance as Glyph);
        }
      }
    }
  }

  var monsters = new Histogram<Breed>();
  for (var actor in stage.actors) {
    if (actor is Monster) {
      var breed = actor.breed;
      monsters.add(breed);
    }
  }

  var tableContents = new StringBuffer();
  tableContents.write('''
    <thead>
    <tr>
      <td>Count</td>
      <td colspan="2">Breed</td>
      <td>Depth</td>
      <td colspan="2">Health</td>
      <td>Exp.</td>
      <!--<td>Drops</td>-->
    </tr>
    </thead>
    <tbody>
    ''');

  for (var breed in monsters.descending()) {
    var glyph = breed.appearance as Glyph;
    tableContents.write('''
      <tr>
        <td>${monsters.count(breed)}</td>
        <td>
          <pre><span style="color: ${glyph.fore.cssColor}">${new String.fromCharCodes([glyph.char])}</span></pre>
        </td>
        <td>${breed.name}</td>
        <td>${breed.depth}</td>
        <td class="r">${breed.maxHealth}</td>
        <td><span class="bar" style="width: ${breed.maxHealth}px;"></span></td>
        <td class="r">${(breed.experienceCents / 100).toStringAsFixed(2)}</td>
        <td>
      ''');

    var attacks = breed.attacks.map(
        (attack) => '${Log.conjugate(attack.verb, breed.pronoun)} (${attack.damage})');
    tableContents.write(attacks.join(', '));

    tableContents.write('</td><td>');

    for (var flag in breed.flags) {
      tableContents.write('$flag ');
    }

    tableContents.write('</td></tr>');
  }
  tableContents.write('</tbody>');

  var validator = new html.NodeValidatorBuilder.common();
  validator.allowInlineStyles();

  html.querySelector('table[id=monsters]').setInnerHtml(tableContents.toString(),
      validator: validator);

  tableContents.clear();
  tableContents.write('''
    <thead>
    <tr>
      <td colspan="2">Item</td>
      <td>Depth</td>
      <td>Tags</td>
      <td>Equip.</td>
      <td>Attack</td>
      <td>Armor</td>
    </tr>
    </thead>
    <tbody>
    ''');

  var items = new Histogram<String>();
  for (var item in stage.allItems) {
    items.add(item.toString());
  }

  tableContents.clear();
  tableContents.write('''
    <thead>
    <tr>
      <td>Count</td>
      <td width="300px">Item</td>
    </tr>
    </thead>
    <tbody>
    ''');

  for (var item in items.descending()) {
    tableContents.write('''
    <tr>
      <td>${items.count(item)}</td>
      <td>$item</td>
    </tr>
    ''');
  }
  html.querySelector('table[id=items]').setInnerHtml(tableContents.toString(),
      validator: validator);
}
