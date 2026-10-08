# Edge Routing — Anti-Overlap Playbook

Everything here was verified by rendering with draw.io Desktop 30.3.13 and inspecting the output.

## Why draw.io will overlap arrows unless you intervene

Draw.io's built-in router is deliberately minimal. It draws each edge as a straight line or a
single right-angle path between `source` and `target` with **no awareness of any other shape**.
There is no obstacle avoidance and no automatic separation of parallel edges.

Two consequences, both of which show up immediately in AWS diagrams:

1. **Pass-through.** An edge between two nodes that have a third node between them runs straight
   across that third node.
2. **Collinear collapse.** Two edges leaving the same node both default to the midpoint of the
   same side, so they are drawn one on top of the other, and their labels land on the same point.

### The automatic escapes do not work here

| Option | Result |
|---|---|
| `--layout libavoid` | **Hangs.** Ran 7+ minutes on a 3-icon diagram, produced no output file and no log. Do not use. |
| `--layout verticalFlow` (ELK) | Works and preserves parent/child nesting, **but** resizes 60×60 icons to fill their subnet, shrinks containers to hug their children, pushes icon labels onto container borders, and forces a portrait aspect. Unusable for AWS architecture; good for flowcharts. |

So for AWS diagrams the routing is manual and must be deterministic.

## Rule 1 — One connection point per edge

The AWS `points=[...]` array on every icon exposes 16 anchors. Address them with
`exitX`/`exitY` on the source and `entryX`/`entryY` on the target, plus the `Dx`/`Dy` zeros:

```
exitX=1;exitY=0.25;exitDx=0;exitDy=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;
```

Fractions are positions along the side: `0` = top/left corner, `0.5` = midpoint, `1` = bottom/right.

Allocation table — for N edges leaving the same side of the same node:

| N | Fractions |
|---|---|
| 1 | `0.5` |
| 2 | `0.25`, `0.75` |
| 3 | `0.25`, `0.5`, `0.75` |
| 4+ | Do not fan out further. Insert a hub node (an Elastic Load Balancing, Amazon EventBridge or Amazon API Gateway icon) and route through it. |

Never reuse a fraction on the same side of the same node.

Side conventions: `exitX=1,exitY=*` right · `exitX=0` left · `exitY=0` top · `exitY=1` bottom.

## Rule 2 — Never attach to the bottom of an icon

AWS icon labels sit **below** the icon (`verticalLabelPosition=bottom`). So `exitY=1` or
`entryY=1` runs the edge straight through the icon's own service name. Verified by rendering: a
bottom exit always crosses the label, because the label is wider than the 60px icon and centred
on it.

Use **top, left or right** only.

To travel downward from a node:

1. Leave from the left or right side.
2. Run a short horizontal **at the icon's own y range** — that band is above the label.
3. Descend in a corridor.

The descending vertical must also avoid:

- **other icons' label spans** — roughly that icon's centre ±60px, at the label's y band
- **container header labels** — they start 30px in from the container's left edge (`spacingLeft=30`)
  and are about 100–150px wide at `fontSize=12`

This is the single most common cause of a diagram that validates but looks wrong.

## Rule 3 — Corridors

A corridor is an empty band reserved for edges. Derive centrelines from the layout grid
(`COL(c) = X0 + c*160`, `ROW(r) = Y0 + r*150`):

- **Vertical corridor** between columns `c` and `c+1`: `x = X0 + c*160 + 110`
- **Horizontal corridor** below row `r`: `y = Y0 + r*150 + 125`

Reserve one **long-haul corridor** inside the outermost container before placing icons —
normally the band just below its 30px header. Every edge that has to travel past other icons
uses it.

Give the edge waypoints on the corridor centreline:

```xml
<mxCell id="e2" value="TCP 6379"
        style="edgeStyle=orthogonalEdgeStyle;rounded=0;html=1;endArrow=open;endFill=0;strokeColor=#545B64;strokeWidth=2;fontSize=10;labelBackgroundColor=#FFFFFF;exitX=0.5;exitY=0;exitDx=0;exitDy=0;entryX=0.5;entryY=0;entryDx=0;entryDy=0;jettySize=20;"
        edge="1" parent="3" source="10" target="12">
  <mxGeometry x="0.2" relative="1" as="geometry">
    <Array as="points">
      <mxPoint x="100" y="70" />
      <mxPoint x="700" y="70" />
    </Array>
    <mxPoint as="offset" x="0" y="-10" />
  </mxGeometry>
</mxCell>
```

Two waypoints is almost always enough: leave the source on a perpendicular, travel the corridor,
arrive on a perpendicular. Do not add more unless the path genuinely needs a third turn.

## Rule 4 — `parent` sets the coordinate space

Waypoint coordinates are relative to the edge's `parent` container, **not** the canvas. Set the
edge's `parent` to the nearest common ancestor of source and target.

| Source / target location | Edge `parent` |
|---|---|
| Both in the same subnet | that subnet |
| Different subnets in one VPC | the VPC |
| Inside VPC ↔ regional service outside the VPC | Region (or AWS Cloud) |
| Inside AWS Cloud ↔ external actor | `"1"` |

An edge parented to a container also renders *inside* it, so a cross-container edge parented too
deeply gets clipped. Parenting too shallowly is safe but your waypoints must then use the
shallower coordinate space.

Symptom of getting this wrong: the arrow shoots to a canvas corner, or vanishes.

## Rule 5 — Label placement

An edge label sits at the edge midpoint by default, so two parallel edges stack their labels.

- **Along the edge**: the `x` attribute of the edge's `mxGeometry` is a relative position,
  `-1` = source end, `0` = midpoint, `1` = target end. Give parallel edges different values
  (e.g. `-0.3` and `0.3`).
- **Off the line**: `<mxPoint as="offset" x="0" y="-10" />` lifts the label 10px above the line.
- **Always** `labelBackgroundColor=#FFFFFF;` so the label masks whatever it crosses.
- Keep labels to a protocol and port: `HTTPS 443`, `TCP 5432`, `TCP 6379`, `async`.

## Rule 6 — Structural requirements

- Every edge `mxCell` must contain an `<mxGeometry>` **child element**. A self-closing edge cell
  (`<mxCell ... edge="1" />`) does not render.
- `jettySize=20` gives the arrowhead a clean straight approach instead of turning at the border.
- `orthogonalLoop=1` keeps self-loops tidy.
- `rounded=1` on the edge softens corridor corners; optional but reads better on dense diagrams.

## Worked example

Amazon EC2 in a public subnet talks to Amazon RDS and Amazon ElastiCache in a private subnet.
Amazon RDS sits between EC2 and ElastiCache on the same row.

**Naive version** — both edges default to the right midpoint of EC2. They become collinear, the
EC2→ElastiCache edge passes straight through the Amazon RDS icon, and the two labels collide.

**Corrected version:**

- `e1` EC2 → Amazon RDS: `exitX=1;exitY=0.5` → `entryX=0;entryY=0.5`. Direct horizontal, nothing
  in between, no waypoints needed.
- `e2` EC2 → Amazon ElastiCache: `exitX=0.5;exitY=0` (leaves the **top**, never the bottom) → two
  waypoints on the VPC's long-haul corridor at `y=70` → `entryX=0.5;entryY=0` (arrives at the
  **top**). Parent is the VPC, because source and target are in different subnets.
- `e1` label offset `y=-10`; `e2` label at relative `x=0.2` with offset `y=-10`.

Result: no edge crosses an icon, no two edges share a segment, both labels legible.
See `examples/aws-3tier-web.drawio` for the full pattern in a larger diagram.

## Checklist

1. No two edges share a connection point on the same side of the same node.
2. No edge uses `exitY=1` or `entryY=1` — that would cross the icon's own label.
3. No descending vertical passes through another icon's label span or a container header label.
4. Every edge whose straight path would cross a third icon has corridor waypoints.
5. Every edge's `parent` is the nearest common ancestor of its source and target.
6. Waypoint coordinates are expressed in that parent's coordinate space.
7. Parallel edges have staggered labels; every label has `labelBackgroundColor=#FFFFFF`.
8. Every edge cell has an `<mxGeometry>` child element.
9. Nodes with 4+ outgoing edges route through a hub instead of fanning out.
