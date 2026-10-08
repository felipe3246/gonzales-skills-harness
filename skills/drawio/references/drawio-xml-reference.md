# draw.io XML Reference

Features beyond basic shapes and edges. Condensed from the official
[draw.io diagram generation reference](https://www.drawio.com/docs/reference/diagram-generation/).

## Layers

A layer is an `mxCell` with `parent="0"` and no `vertex`/`edge` attribute. Cells join a layer by
setting `parent` to the layer id. Later layers render above earlier ones. Add `visible="0"` to
hide a layer by default.

```xml
<mxCell id="0" />
<mxCell id="1" parent="0" />
<mxCell id="2" value="Annotations" parent="0" />
<mxCell id="20" value="Deprecated" style="text;html=1;" vertex="1" parent="2">
  <mxGeometry x="100" y="170" width="120" height="30" as="geometry" />
</mxCell>
```

Useful for architecture diagrams that carry several views — "Network", "Security zones",
"Data flow" — that a viewer can toggle independently.

## Tags

Tags are visibility filters. Unlike layers, one cell can carry several tags. They require an
`<object>` wrapper; a plain `mxCell` cannot have tags. The `label` attribute replaces `value`.

```xml
<object id="2" label="Auth Service" tags="critical v2">
  <mxCell style="rounded=1;whiteSpace=wrap;html=1;" vertex="1" parent="1">
    <mxGeometry x="100" y="100" width="120" height="60" as="geometry" />
  </mxCell>
</object>
```

Viewers filter via Edit > Tags. Tags do not affect z-order or containment.

## Metadata and placeholders

Custom properties are plain attributes on `<object>`. Set `placeholders="1"` to substitute
`%propertyName%` into the label or tooltip.

```xml
<object id="2" label="&lt;b&gt;%component%&lt;/b&gt;&lt;br&gt;Owner: %owner%&lt;br&gt;Status: %status%"
        placeholders="1" component="Auth Service" owner="Team Backend" status="Active">
  <mxCell style="rounded=1;whiteSpace=wrap;html=1;" vertex="1" parent="1">
    <mxGeometry x="100" y="100" width="160" height="80" as="geometry" />
  </mxCell>
</object>
```

- Resolution walks up the containment hierarchy: cell, then parent, then layer, then root.
- Predefined: `%id%`, `%width%`, `%height%`, `%date%`, `%time%`, `%timestamp%`, `%page%`,
  `%pagenumber%`, `%pagecount%`, `%filename%`. `%%` is a literal percent.
- Without `placeholders="1"`, `%name%` renders as literal text.

Good fit for AWS diagrams where icons represent real resources — attach instance type, CIDR,
account id, environment.

### File-level variables

`<mxfile vars='{"project":"Atlas","version":"2.1"}'>` defines globals referenced as `%project%`.
Only available in the full `<mxfile>` form. Users edit them via File > Properties > Edit Data.

## Dark mode

- `strokeColor`, `fillColor`, `fontColor` default to `default`, which renders black in light theme
  and white in dark.
- An explicit colour is the light-mode value; the dark value is derived automatically by inverting
  RGB and rotating hue 180°.
- To control both, use `light-dark(lightColor,darkColor)`, e.g.
  `fontColor=light-dark(#7EA6E0,#FF0000)`.
- Requires `adaptiveColors="auto"` on `mxGraphModel`.

Usually no action needed — the automatic inverse is fine. AWS category colours invert acceptably.

## HTML labels

- Add `html=1` to **every** style. Harmless for plain text, required for any tag.
- Escape inside attributes: `&lt;` `&gt;` `&amp;` `&quot;`.
- Line break: `&#xa;` (works with `html=1` and `html=0`) or `&lt;br&gt;` (needs `html=1`).
  **Never `\n`** — it renders as literal backslash-n.
- Whole-label emphasis: `fontStyle=1` bold, `2` italic, `4` underline, combined bitwise
  (`3` = bold+italic). Use `<b>`/`<i>` tags only for part of a label. Do not combine both
  mechanisms for the same effect.

## Containers

| Type | Style | When |
|---|---|---|
| Group (invisible) | `group;` (includes `pointerEvents=0`) | No border needed, container has no connections |
| Swimlane (titled) | `swimlane;startSize=30;` | Needs a header, or the container itself connects |
| Custom | add `container=1;pointerEvents=0;` to any shape | Any shape acting as a container |

Children set `parent="<containerId>"` and use **coordinates relative to the parent**, with the
origin below the header. Edges crossing a container border are normal and expected — do not add
waypoints just to dodge a parent.

## Cross-functional flowcharts (actor × phase)

For a process across two axes, use the `table` shape rather than plain swimlanes.

- Table: `shape=table;childLayout=tableLayout;startSize=0;collapsible=0;fillColor=none;`
- Rows (children of table): `shape=tableRow;horizontal=0;startSize=0;collapsible=0;`
- Cells (children of rows): regular vertices, one per intersection
- Process nodes go inside the cell (`parent="<cellId>"`)
- Cross-cell edges use `parent="1"`

Do not nest swimlanes in a table row, and do not set `startSize` on rows or cells. `tableLayout`
normalises approximate widths.

For one axis only, use flat swimlanes at `parent="1"`:
`swimlane;horizontal=0;startSize=110;fillColor=<pastel>;html=1;`, children at `x = 120 + col*180`,
`y = 45`. Cross-lane edges use `parent="1"`.

## Edge style families

| Style | Syntax | Use |
|---|---|---|
| Orthogonal | `edgeStyle=orthogonalEdgeStyle` | Flowcharts, architecture, network |
| Straight | no `edgeStyle` | UML class, sequence |
| Entity relation | `edgeStyle=entityRelationEdgeStyle` | ER diagrams (perpendicular stubs) |
| Curved | `curved=1` | Mind maps |
| Elbow | `edgeStyle=elbowEdgeStyle;elbow=vertical;` | Rarely needed |

Use one family consistently per diagram.

## Compressed format

draw.io saves compressed by default, but **never generate compressed content** — it costs more
tokens than raw XML and cannot be validated or diffed. Compression is only needed for URLs
(see `general-diagrams.md`).

## Well-formedness rules

- **Never emit XML comments.** Strictly forbidden — wasted tokens, possible parse errors.
- Escape `&` `<` `>` `"` in attribute values.
- All `id` values unique.
- `vertex="1"` and `edge="1"` are mutually exclusive.
- Non-rectangular shapes need a matching `perimeter=` (e.g. `ellipse` needs
  `perimeter=ellipsePerimeter`).
- `(0,0)` is top-left; x grows right, y grows down.

Validate structure with `mxfile.xsd`. Note it only accepts the full `<mxfile>` form — a bare
`<mxGraphModel>` is valid draw.io but unvalidatable — and it does **not** check style strings or
shape names.
