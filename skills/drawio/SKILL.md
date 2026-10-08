---
name: drawio
description: Generate diagrams as native, editable .drawio files (draw.io / diagrams.net) with optional PNG/SVG/PDF export or an app.diagrams.net link. Use whenever the user asks for a draw.io or .drawio file, an AWS architecture diagram with official AWS icons (VPC, subnets, services), or a diagram they will keep editing in draw.io, even if they only say "architecture diagram" or "infrastructure diagram". Also handles flowcharts, sequence, ER and other standard diagram types when the output should be a .drawio. Not for diagrams delivered as styled HTML/SVG pages.
argument-hint: "<format> <description>"
---

# Draw.io Diagram Skill

Generate draw.io diagrams as native `.drawio` files. Optionally export to PNG, SVG, or PDF with embedded XML (so the exported file stays editable in draw.io).

## Choose the authoring route first

Check for the draw.io CLI before choosing (paths in [draw.io CLI](#drawio-cli)). Without it, Mermaid conversion, ELK layout and image export are unavailable: hand-written XML is the only authoring route, and the deliverable is the `.drawio` file (or a `url`).

| Diagram | Route | Why |
|---------|-------|-----|
| **AWS / cloud architecture** (VPC, subnets, nested containers) | **Hand-written XML** with the layout grid below | Spatial position carries meaning. Auto-layout destroys it — see `references/general-diagrams.md` for proof. |
| Flowchart, sequence, class, state, ER, gantt, mindmap, C4, journey | **Mermaid → CLI converts** | draw.io's parser lays it out for you. Far more reliable than hand-positioning. |
| Anything needing precise styling or a specific shape library | Hand-written XML | Full control. |

## Pipeline

The request may start with an output format (`png`, `svg`, `pdf`, `url`); with no format, the deliverable is the `.drawio` alone.

Paths under `references/` and `scripts/` are relative to this skill's directory, not to the working directory; resolve them against the skill's install location before reading or running anything.

1. **Author → `.drawio`**
   - Mermaid: write `diagram.mmd`, then `drawio -x -f xml -o diagram.drawio diagram.mmd`, then delete the `.mmd`.
   - XML: write `diagram.drawio` directly following the rules below.
2. **Validate** — always run the validator before delivering (see [Validation](#validation)).
3. **Deliver**
   - no format → keep `diagram.drawio`
   - `png` / `svg` / `pdf` → export with `-e` (embedded XML). **Keep the `.drawio` source** — the user needs it for future edits. Both files coexist.
     After exporting, look at the rendered image if your harness can display it: the validator cannot see overlaps, so check that no arrow crosses an icon or a label and no two arrows share a segment. Fix the XML, re-validate and re-export before delivering.
   - `url` → build an `app.diagrams.net` link (see `references/general-diagrams.md`)
4. **Open** the result. If opening fails, print the absolute path.

## draw.io CLI

Detect the platform, then locate the binary:

| Platform | Path |
|----------|------|
| macOS | `/Applications/draw.io.app/Contents/MacOS/draw.io` |
| Linux | `drawio` (usually on PATH) |
| WSL2 (`/proc/version` contains `microsoft`) | `"/mnt/c/Program Files/draw.io/draw.io.exe"` |
| Windows | `"C:\Program Files\draw.io\draw.io.exe"` |

```bash
drawio -x -f <format> -e -b 10 -o <output> <input>
```

`-x` export · `-f` format (`xml`, png, svg, pdf) · `-e` embed diagram XML · `-b` border · `-o` output · `-s` scale · `-a` all pages (PDF) · `--layout <preset>` run an ELK layout.

Opening: `open` (macOS) · `xdg-open` (Linux) · `cmd.exe /c start "" "$(wslpath -w <file>)"` (WSL2) · `start` (Windows).

**Do not use `--layout libavoid`.** It hangs indefinitely and never writes output. Obstacle avoidance must be done manually — that is what the routing rules below are for.

**Do not use `--layout` at all on AWS container diagrams.** ELK resizes service icons to fill their subnet, shrinks containers to hug their children, and pushes labels onto container borders. It is fine for flowcharts, wrong for architecture.

---

# AWS Architecture Diagrams

## RULE 1 — Always use the official service name

Every AWS icon label MUST be the official service name, including the `Amazon` or `AWS` prefix. Never abbreviate to a bare acronym.

| Correct | Wrong |
|---------|-------|
| `Amazon EC2` | `EC2` |
| `Amazon S3` | `S3`, `Simple Storage Service` |
| `AWS Lambda` | `Lambda` |
| `Amazon RDS` | `RDS`, `Database` |
| `Elastic Load Balancing` | `ELB`, `Load Balancer` |
| `Amazon Data Firehose` | `Kinesis Data Firehose` (renamed Feb 2024) |
| `Amazon SageMaker AI` | `SageMaker` (renamed Dec 2024) |

The prefix is part of the name and is not interchangeable: `Amazon EC2` but `AWS Lambda`. Look up the exact name and its `resIcon` in **`references/aws-service-catalog.md`** — do not guess it.

Sub-resources that AWS documents in lowercase stay lowercase: `NAT gateway`, `internet gateway`, `Availability Zone`.

Because official names are long, they change the layout maths — see RULE 2.

## RULE 2 — Layout grid

Fixed pitches. Derive every coordinate from the formulas below instead of inventing spacing.

- Service icon size: **60×60** (never resize; `aspect=fixed`)
- Column: `COL(c) = X0 + c*160` — **160px horizontal pitch is the minimum** that keeps official service names from colliding
- Row: `ROW(r) = Y0 + r*150`
- Container padding: 20px from all edges; 30px between sibling containers
- Container header (`startSize` / label band): 30px, so the first child row starts at `y >= 40`

**Labels.** `verticalLabelPosition=bottom;verticalAlign=top;` puts the name under the icon. `labelWidth` and `whiteSpace=wrap` have **no effect** on bottom labels — verified. So:

- name ≤ 18 characters → single line, reserve 20px below the icon
- name > 18 characters → insert an explicit break `&#xa;` at a word boundary, reserve 36px

```
value="Amazon Simple&#xa;Notification Service"
```

## RULE 3 — Arrows must never overlap

Draw.io's built-in router has **no obstacle awareness**: it draws a straight or single-right-angle path and will run an edge straight through any icon in between. Two edges leaving the same node both default to the side midpoint, so they land exactly on top of each other. Both failures are avoided by the four rules below.

### 3a. Never let two edges share a connection point

Every edge declares its exit and entry explicitly. The AWS `points=[...]` array exposes sixteen anchors; use the `0.25 / 0.5 / 0.75` fractions of a side to fan out.

```
exitX=1;exitY=0.25;exitDx=0;exitDy=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;
```

With N edges on one side, assign `0.25`, `0.5`, `0.75` in order. Never reuse a fraction on the same side of the same node.

### 3b. Never attach to the bottom of an icon

The service name sits **below** the icon, so `exitY=1` or `entryY=1` puts the edge straight through the icon's own label. Use the **top, left or right** side only. To go downward, leave from a side, run a short horizontal at the icon's own y (which is above the label), then descend in a corridor.

For the same reason, a descending vertical must not land inside another icon's label span — roughly that icon's centre ±60px — nor inside a container's header label, which starts 30px in from the container's left edge.

### 3c. Route skip-edges through a corridor

An edge whose straight path would cross a third icon must be routed around it through a reserved empty band. Corridor centrelines follow from the grid:

- vertical corridor between columns `c` and `c+1`: `x = X0 + c*160 + 110`
- horizontal corridor below row `r`: `y = Y0 + r*150 + 125`

Give the edge two waypoints on that centreline:

```xml
<mxGeometry relative="1" as="geometry">
  <Array as="points">
    <mxPoint x="100" y="70" />
    <mxPoint x="700" y="70" />
  </Array>
</mxGeometry>
```

Reserve one empty band inside the outermost container (typically just below its header) as the long-haul corridor before placing any icons.

### 3d. The edge's `parent` decides the waypoint coordinate space

Set the edge's `parent` to the **nearest common ancestor** of source and target. Waypoints are interpreted in **that container's** coordinate space, not the canvas.

| Source and target | Edge `parent` |
|---|---|
| same subnet | that subnet |
| different subnets, same VPC | the VPC |
| inside VPC ↔ outside VPC | AWS Cloud (or `"1"`) |

Getting this wrong is the most common cause of an arrow flying off to a corner.

### 3e. Stagger the labels

Two parallel edges put their labels at the same midpoint. Move them apart along the edge with the relative `x` (`-1` = source, `0` = middle, `1` = target) and lift them off the line with an offset:

```xml
<mxGeometry x="0.2" relative="1" as="geometry">
  <mxPoint as="offset" x="0" y="-10" />
</mxGeometry>
```

Always add `labelBackgroundColor=#FFFFFF;` so the text never blends into a line it crosses.

### Pre-write checklist

1. No two edges share a connection point on the same side of the same node.
2. No edge attaches to the bottom of an icon.
3. Every edge whose straight path crosses a third icon has corridor waypoints.
4. Every edge's `parent` is the nearest common ancestor of source and target.
5. Parallel edges have staggered labels; every edge label has a white background.
6. Every edge `mxCell` contains an `<mxGeometry>` **child element** — a self-closing edge cell does not render.
7. `jettySize=20` on orthogonal edges so the arrowhead has a clean straight approach.

Deep dive and worked examples: **`references/edge-routing.md`**.

## Icon conventions

Three distinct forms — using the wrong one is off-brand:

| Use for | Style | Renders as |
|---------|-------|------------|
| **A service** (Amazon EC2, AWS Lambda) | `shape=mxgraph.aws4.resourceIcon;resIcon=<name>` + `fillColor=<category>;strokeColor=#ffffff` | Coloured square, white glyph |
| **A specific resource** (one ALB, one Lambda function) | `shape=mxgraph.aws4.<name>` + `fillColor=<category>;strokeColor=none` | Line-art glyph, no tile |
| **VPC components & external actors** (NAT gateway, Users) | `shape=mxgraph.aws4.resourceIcon;resIcon=<name>` + `fillColor=#ffffff;strokeColor=#232F3E` | White tile, dark glyph |

Shared base style for all three:

```
sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];
outlineConnect=0;fontColor=#232F3E;gradientColor=none;dashed=0;
verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=11;fontStyle=0;aspect=fixed;
```

`gradientColor=none` is required. The current AWS icon set is **flat** — only 6 of 575 official icons use a gradient. Never emit `gradientColor=#RRGGBB` or `gradientDirection`.

### Category colours (current AWS palette)

| Category | fillColor | Examples |
|----------|-----------|----------|
| Compute | `#ED7100` | Amazon EC2, Amazon ECS, Amazon EKS, AWS Fargate, AWS Lambda, AWS Batch |
| Storage | `#7AA116` | Amazon S3, Amazon EBS, Amazon EFS, Amazon S3 Glacier, AWS Backup |
| Database | `#C925D1` | Amazon RDS, Amazon Aurora, Amazon DynamoDB, Amazon ElastiCache, Amazon Neptune |
| Networking & Content Delivery | `#8C4FFF` | Amazon VPC, Amazon CloudFront, Amazon Route 53, Elastic Load Balancing, AWS Direct Connect |
| Security, Identity & Compliance | `#DD344C` | AWS IAM, Amazon Cognito, AWS KMS, AWS WAF, AWS Shield, Amazon GuardDuty |
| App Integration & Management | `#E7157B` | Amazon SQS, Amazon SNS, Amazon EventBridge, AWS Step Functions, Amazon API Gateway, Amazon CloudWatch, AWS CloudFormation |
| Analytics | `#8C4FFF` | Amazon Kinesis Data Streams, Amazon Data Firehose, Amazon Athena, AWS Glue, Amazon EMR |
| Machine Learning | `#01A88D` | Amazon SageMaker AI, Amazon Bedrock, Amazon Comprehend, Amazon Textract |
| Developer Tools | `#C925D1` | AWS CodePipeline, AWS CodeBuild, AWS CodeDeploy |
| Neutral / actors | `#ffffff` + `strokeColor=#232F3E` | Users, Client, NAT gateway, internet gateway, AWS Certificate Manager |

Exact `resIcon` per service: **`references/aws-service-catalog.md`**. Machine-checkable name lists: `references/valid-aws4-resicons.tsv`, `references/valid-aws4-shapes.tsv`, `references/valid-aws4-groups.tsv`.

### Example: service icon

```xml
<mxCell id="10" value="Amazon EC2" style="sketch=0;points=[[0,0,0],[0.25,0,0],[0.5,0,0],[0.75,0,0],[1,0,0],[0,1,0],[0.25,1,0],[0.5,1,0],[0.75,1,0],[1,1,0],[0,0.25,0],[0,0.5,0],[0,0.75,0],[1,0.25,0],[1,0.5,0],[1,0.75,0]];outlineConnect=0;fontColor=#232F3E;gradientColor=none;fillColor=#ED7100;strokeColor=#ffffff;dashed=0;verticalLabelPosition=bottom;verticalAlign=top;align=center;html=1;fontSize=11;fontStyle=0;aspect=fixed;shape=mxgraph.aws4.resourceIcon;resIcon=mxgraph.aws4.ec2;" vertex="1" parent="4">
  <mxGeometry x="40" y="40" width="60" height="60" as="geometry" />
</mxCell>
```

## Group containers

Base style for every AWS group:

```
points=[[0,0],[0.25,0],[0.5,0],[0.75,0],[1,0],[1,0.25],[1,0.5],[1,0.75],[1,1],[0.75,1],[0.5,1],[0.25,1],[0,1],[0,0.75],[0,0.5],[0,0.25]];
outlineConnect=0;gradientColor=none;html=1;whiteSpace=wrap;fontSize=12;fontStyle=0;shape=mxgraph.aws4.group;
verticalAlign=top;align=left;spacingLeft=30;labelBackgroundColor=none;container=1;pointerEvents=0;
collapsible=0;recursiveResize=0;
```

`spacingLeft=30` clears the `grIcon` badge. `pointerEvents=0` stops the container capturing child connections.

| Group | grIcon | strokeColor | fillColor | fontColor | dashed |
|-------|--------|-------------|-----------|-----------|--------|
| AWS Cloud | `group_aws_cloud_alt` | `#232F3E` | none | `#232F3E` | 0 |
| AWS Account | `group_account` | `#CD2264` | none | `#CD2264` | 0 |
| Region | `group_region` | `#00A4A6` | none | `#00A4A6` | 1 |
| Availability Zone | `group_availability_zone` | `#00A4A6` | none | `#00A4A6` | 1 |
| VPC | `group_vpc` | `#8C4FFF` | none | `#8C4FFF` | 0 |
| Public subnet | `group_security_group` | `#7AA116` | `#E9F3D2` | `#248814` | 0 |
| Private subnet | `group_security_group` | `#00A4A6` | `#E6F6F7` | `#147EBA` | 0 |
| Security group | `group_security_group` | `#DD344C` | `#F2DEDE` | `#DD344C` | 0 |
| Auto Scaling group | `group_auto_scaling_group` | `#ED7100` | none | `#ED7100` | 1 |
| Corporate data center | `group_corporate_data_center` | `#7D8998` | none | `#5A6C86` | 0 |

Nesting order: External actors → AWS Cloud → AWS Account → Region → VPC → Availability Zone → Subnet → services.

The stroke colours above are AWS's current architecture-diagram convention (VPC in the Networking purple, subnets in their public/private colours). draw.io's shape picker still ships several of these groups with a neutral grey default (`#879196` for Region, VPC and Auto Scaling; `#545B64` for Availability Zone). Prefer the table — it is the deliberate choice, not a mistake. `references/valid-aws4-groups.tsv` records draw.io's shipped defaults if you need them.

Placement by scope:

- **Outside Region** (global): Amazon Route 53, Amazon CloudFront, AWS IAM, AWS WAF
- **In Region, outside VPC**: Amazon S3, Amazon DynamoDB, Amazon SQS, Amazon SNS, AWS Lambda, Amazon API Gateway
- **In VPC, outside subnet**: NAT gateway, internet gateway, Elastic Load Balancing
- **In subnet**: Amazon EC2, Amazon RDS, Amazon ElastiCache

Annotate CIDR blocks on VPC and subnets, and mark Multi-AZ / Auto Scaling where relevant.

## Connector styles

| Meaning | Style |
|---------|-------|
| Synchronous data flow | `edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=20;html=1;endArrow=open;endFill=0;strokeColor=#545B64;strokeWidth=2;` |
| Async / event | same + `dashed=1;strokeColor=#E7157B;` |
| Encrypted | same + `dashed=1;dashPattern=5 5;strokeColor=#DD344C;endArrow=classic;endFill=1;` |

Always add `fontSize=10;labelBackgroundColor=#FFFFFF;` when the edge carries a label. Label edges with the protocol and port (`HTTPS 443`, `TCP 5432`).

---

# XML structure

```xml
<mxfile host="app.diagrams.net">
  <diagram id="diagram-1" name="Architecture">
    <mxGraphModel dx="1434" dy="759" grid="1" gridSize="10" guides="1"
      tooltips="1" connect="1" arrows="1" fold="1" page="1" pageScale="1"
      pageWidth="1169" pageHeight="827" math="0" shadow="0" adaptiveColors="auto">
      <root>
        <mxCell id="0" />
        <mxCell id="1" parent="0" />
      </root>
    </mxGraphModel>
  </diagram>
</mxfile>
```

- Use the full `<mxfile>` wrapper. A bare `<mxGraphModel>` is valid draw.io but **fails XSD validation**, so it cannot be checked.
- `adaptiveColors="auto"` enables dark-mode adaptation.
- IDs `0` and `1` are reserved; start your own at `2` and keep them unique.
- Landscape `1169×827` for architecture.
- **Never emit XML comments** (`<!-- -->`) — they waste tokens and can break parsing.
- Escape `&`→`&amp;`, `<`→`&lt;`, `>`→`&gt;`, `"`→`&quot;` in attribute values.
- Line breaks in labels: `&#xa;`. Never `\n`.
- Add `html=1` to every style.

Layers, tags, custom metadata, placeholders, dark-mode `light-dark()`, and cross-functional tables: **`references/drawio-xml-reference.md`**.

## Validation

Run before delivering. The XSD checks structure only — it will happily accept an invalid shape name — so the shape-name check is a separate and necessary step.

```bash
<skill-dir>/scripts/validate-drawio.sh diagram.drawio
```

It verifies XML well-formedness, XSD conformance, that every `resIcon`/`shape`/`grIcon` name exists, that no edge cell is self-closing, that no gradient is used, and that no XML comment slipped in.
It also checks that ids are unique, that every `parent` resolves, and that no label contains a literal `\n`. Fix every `FAIL` and re-run until the file prints `PASS` (exit code 0). If it prints `skip  xmllint not installed`, well-formedness and XSD were not checked and the result is weaker. It needs `python3`; `xmllint` is optional.

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| Icon is a blank coloured square | `resIcon`/`shape` name does not exist | Look it up in `references/valid-aws4-resicons.tsv`. Names are `snake_case`, never camelCase |
| Arrow crosses an icon | No corridor waypoints | Apply RULE 3c |
| Two arrows drawn on top of each other | Both use the side midpoint | Apply RULE 3a |
| Arrow flies to a far corner | Edge `parent` is not the common ancestor | Apply RULE 3d |
| Arrow crosses an icon's own name | Edge attached to the icon's bottom | Apply RULE 3b |
| Edge missing entirely | Edge `mxCell` is self-closing | Add the `<mxGeometry relative="1" as="geometry" />` child |
| Labels overlap each other | Pitch below 160px, or long name on one line | Apply RULE 2 |
| `--layout libavoid` never finishes | Known hang in draw.io Desktop | Do not use it; route manually |
| Blank diagram | Missing root cells | Ensure `id="0"` and `id="1"` exist |
| CLI not found | Desktop app not installed | Deliver the `.drawio` and tell the user which install unlocks export |

## References

| File | Contents |
|------|----------|
| `references/aws-service-catalog.md` | Official service names → `resIcon` → category colour |
| `references/edge-routing.md` | Anti-overlap routing playbook with worked examples |
| `references/drawio-xml-reference.md` | Layers, tags, metadata, placeholders, dark mode, tables |
| `references/general-diagrams.md` | Mermaid route, ELK presets, URL output, non-AWS shapes |
| `references/valid-aws4-resicons.tsv` | 554 valid `resIcon` names with titles and official colours |
| `references/valid-aws4-shapes.tsv` | 595 valid dedicated shape names |
| `references/valid-aws4-groups.tsv` | 19 valid container `grIcon` names |
| `references/mxfile.xsd` | Schema for structural validation |
| `references/examples/` | Validated, overlap-free diagrams to copy from |

Start from an example in `references/examples/` whenever the request matches one — the coordinates and routing there are already verified.
