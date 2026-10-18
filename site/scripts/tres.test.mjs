import { test } from "node:test";
import assert from "node:assert/strict";
import { parseTres, heroFromTres } from "./tres.mjs";

const TRES = `[gd_resource type="Resource" script_class="HeroData" format=3 uid="uid://x"]

[ext_resource type="Script" path="res://shared/resources/hero_data.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://shared/ui/icons/knight_q.svg" id="icon_q"]

[sub_resource type="Resource" id="q"]
script = ExtResource("2_skill")
id = &"knight_q"
display_name = "Investida"
description = "Avança 6 u e empurra. Dano: base + 75% do ATQ."
icon = ExtResource("icon_q")
cooldown = PackedFloat64Array(8)

[resource]
script = ExtResource("1_script")
id = &"knight"
display_name = "Cavaleiro"
role = "Tanque"
summary = "Absorção de dano."
base_hp = 600.0
skill_q = SubResource("q")
`;

test("parseTres separa ext_resource, sub_resource e resource", () => {
  const t = parseTres(TRES);
  assert.equal(t.ext.icon_q, "res://shared/ui/icons/knight_q.svg");
  assert.equal(t.sub.q.display_name, "Investida");
  assert.equal(t.sub.q.id, "knight_q"); // &"..." vira string
  assert.equal(t.resource.display_name, "Cavaleiro");
  assert.equal(t.resource.base_hp, 600); // número vira number
  assert.equal(t.resource.skill_q, "q"); // SubResource("q") vira o id
});

test("heroFromTres monta o herói com a skill e o nome do ícone", () => {
  const h = heroFromTres(TRES);
  assert.equal(h.id, "knight");
  assert.equal(h.role, "Tanque");
  assert.equal(h.weapon, "");
  assert.deepEqual(h.skills, [
    { key: "Q", name: "Investida", description: "Avança 6 u e empurra. Dano: base + 75% do ATQ.", icon: "knight_q.svg" },
  ]);
});
