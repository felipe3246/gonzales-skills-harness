# Non-AWS Diagrams — Mermaid, Layout, URL Output

## Prefer Mermaid for standard diagram types

The draw.io CLI converts Mermaid to a native `.drawio`, and its parser lays the diagram out for
you. That is far more reliable than hand-positioning cells, so for these types write Mermaid:

flowchart · sequence · class · state · ER · gantt · mindmap · timeline · journey · quadrant ·
requirement · sankey · xychart · block · C4 · gitgraph · pie · radar · packet · venn · treemap ·
kanban · Wardley map · Ishikawa (fishbone)

```bash
printf 'flowchart TD\n  A[User] --> B{Auth?}\n  B -- yes --> C[Dashboard]\n  B -- no --> D[Login]\n' > diagram.mmd
drawio -x -f xml -o diagram.drawio diagram.mmd
rm diagram.mmd
```

The `.drawio` is the artifact — delete the `.mmd`. No `--layout` is needed; the Mermaid parser has
already positioned everything.

**Always convert to `.drawio` first, then export.** Exporting a `.mmd` straight to PNG with `-e`
crashes in current draw.io Desktop. The two-step path is reliable.

Match label language to the user's language.

Full Mermaid syntax reference:
https://raw.githubusercontent.com/jgraph/drawio-mcp/main/shared/mermaid-reference.md

## ELK auto-layout for XML

When you author XML for a *non-AWS* diagram, you can skip coordinate maths entirely: emit nodes at
rough (or zero) positions and let ELK place them.

```bash
drawio -x -f xml --layout verticalFlow -o diagram.drawio diagram.drawio
```

Reading and overwriting the same path is supported. Layout can also be combined with export:

```bash
drawio -x -f png -e -b 10 --layout verticalFlow -o diagram.drawio.png diagram.drawio
```

| Preset | Layout |
|---|---|
| `verticalFlow` | Layered top-to-bottom — flowcharts, pipelines |
| `horizontalFlow` | Layered left-to-right |
| `verticalTree` | Tree top-down — hierarchies, org charts |
| `horizontalTree` | Tree left-to-right |
| `radialTree` | Radial |
| `organic` | Force-directed — networks, mind maps |

Custom form, a JSON array:

```bash
drawio -x -f xml --layout '[{"layout":"elkLayered","config":{"elk.direction":"RIGHT"}}]' -o d.drawio d.drawio
```

Algorithms: `elkLayered`, `elkTree`, `elkRadial`, `elkOrganic`, `elkStress`, `elkBox`. Config keys
prefixed `elk.` are ELK options (`elk.direction`, `elk.spacing.nodeNode`,
`elk.layered.spacing.nodeNodeBetweenLayers`); `edgeStyle` and `corners` control connector rendering.

### Do not use ELK on AWS architecture diagrams

Verified behaviour on a nested AWS diagram: ELK preserves the parent/child hierarchy but resizes
60×60 service icons to fill their subnet, shrinks containers to hug their children, pushes icon
labels onto container borders, and forces portrait. AWS layouts encode meaning in position —
route them manually per `edge-routing.md`.

### Do not use `--layout libavoid`

It hangs indefinitely. Verified: 7+ minutes on a 3-icon diagram, no output file, no log entry.

## URL output

When the user asks for a `url`, build a link that opens the diagram in the browser editor. Only
Node built-ins are needed.

```bash
URL=$(node -e '
const fs = require("fs");
const zlib = require("zlib");
const xml = fs.readFileSync(process.argv[1], "utf8");
const compressed = zlib.deflateRawSync(encodeURIComponent(xml)).toString("base64");
const payload = encodeURIComponent(JSON.stringify({ type: "xml", compressed: true, data: compressed }));
console.log("https://app.diagrams.net/?grid=0&pv=0&border=10&edit=_blank#create=" + payload);
' diagram.drawio)
open "$URL"      # macOS;  xdg-open on Linux
```

Keep the `.drawio` on disk as the persistent copy and print the URL so the user can share it.

On Windows and WSL2, `cmd.exe`'s `start` treats `&` as a separator and strips everything after
`#` — which is where the diagram lives. Write a `.url` shortcut instead:

```bash
TMPFILE=$(mktemp --suffix=.url)
printf '[InternetShortcut]\r\nURL=%s\r\n' "$URL" > "$TMPFILE"
cmd.exe /c start "" "$(wslpath -w "$TMPFILE")"
```

Very large diagrams can exceed browser URL limits; fall back to opening the local file.

Optional query params: `lightbox=1`, `edit=_blank`, `dark=1`, `grid=0`, `pv=0`, `border=10`.

The `#create` JSON also accepts `"type":"csv"` and `"type":"mermaid"`, and an optional
`"layout":"verticalFlow"` to lay the diagram out after creation.

## Standard shape styles

| Element | Style |
|---|---|
| Rounded rectangle | `rounded=1;whiteSpace=wrap;html=1;fillColor=#DAE8FC;strokeColor=#6C8EBF;` |
| Rectangle | `rounded=0;whiteSpace=wrap;html=1;` |
| Diamond (decision) | `rhombus;whiteSpace=wrap;html=1;fillColor=#FFF2CC;strokeColor=#D6B656;` |
| Ellipse | `ellipse;whiteSpace=wrap;html=1;fillColor=#D5E8D4;strokeColor=#82B366;` |
| Database cylinder | `shape=cylinder3;whiteSpace=wrap;html=1;boundedLbl=1;backgroundOutline=1;size=15;` |
| Document | `shape=mxgraph.flowchart.document;whiteSpace=wrap;html=1;` |
| Swimlane | `swimlane;startSize=30;html=1;fontStyle=1;` |
| UML lifeline | `shape=umlLifeline;perimeter=lifelinePerimeter;size=16;` |
| Text only | `text;html=1;` |

Palette: blue `#DAE8FC`/`#6C8EBF` · green `#D5E8D4`/`#82B366` · yellow `#FFF2CC`/`#D6B656` ·
red `#F8CECC`/`#B85450` · purple `#E1D5E7`/`#9673A6` · grey `#F5F5F5`/`#666666`.

Node sizes: rectangles 140×60, diamonds 140×80, circles 60×60, documents 120×80, cylinders 100×70.

Choose semantically correct shapes — `shape=cylinder3` for a database, `rhombus` for a decision.
draw.io has large domain libraries (Cisco, Azure, GCP, Kubernetes, P&ID, BPMN); prefer a real
symbol over a labelled box when the domain expects one.
