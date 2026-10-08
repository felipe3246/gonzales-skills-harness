# Validated Examples

Every `.drawio` here passes `scripts/validate-drawio.sh` and has been rendered and visually
inspected: no arrow crosses an icon, no two arrows overlap, no arrow crosses a label. The `.png`
next to each file is that verified render.

**Start from the closest example rather than deriving coordinates from scratch.** Copy the file,
swap the icons and labels, and keep the container geometry and corridor lines.

| File | Pattern | Techniques it demonstrates |
|------|---------|----------------------------|
| `aws-3tier-web.drawio` | 3-tier web app: Amazon CloudFront → Elastic Load Balancing → Amazon EC2 → Amazon RDS, with a NAT gateway and Amazon S3 | 4-level nesting (AWS Cloud → Region → VPC → subnet); long-haul corridor inside the VPC; a skip-edge that would otherwise cross Amazon RDS; side-exit-then-descend to avoid labels; distinct connection points on Amazon EC2's left side |
| `aws-serverless-api.drawio` | Serverless API: Amazon API Gateway → AWS Lambda → Amazon DynamoDB, async branch through Amazon SQS to Amazon Bedrock | Regional services with no VPC; a fan-out hub (AWS Lambda with three outgoing edges on three different sides); a skip-edge over Amazon DynamoDB via the region corridor; a bottom-corridor return path into Amazon CloudWatch |

## Corridors used

Both diagrams reserve a **long-haul corridor** just below the header of their outermost container
and route every cross-container edge through it:

- `aws-3tier-web`: VPC corridor at VPC-relative `y=55`; inter-row corridor at `y=170`; the gap
  between the two subnets at `x=315`
- `aws-serverless-api`: Region corridor at region-relative `y=55`; bottom return corridor at
  `y=380`; the gap between AWS Lambda worker and Amazon Bedrock at `x=490`

## Regenerating

The examples were produced by a coordinate generator rather than written by hand, so the grid and
corridor arithmetic is exact. If you change one, re-run the validator and re-render before
committing:

```bash
scripts/validate-drawio.sh references/examples/*.drawio
/Applications/draw.io.app/Contents/MacOS/draw.io -x -f png -e -b 10 -s 1.3 \
  -o references/examples/aws-3tier-web.png references/examples/aws-3tier-web.drawio
```

Then open the PNG and confirm visually. The validator cannot see overlaps — only a render can.
