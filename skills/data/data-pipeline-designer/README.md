# Data Pipeline Designer

Design a high-level data pipeline for source-to-target data flows.

## What this skill does

This skill takes a source system, target platform, and consumer requirements and produces a structured pipeline design covering ingestion pattern, processing flow, transformation approach, quality checks, error handling, observability, and operational considerations.

## When to use it

- You need to design a new data pipeline from source to target
- You are evaluating batch vs streaming vs CDC for a specific use case
- You need to document or review an existing pipeline design
- You are scoping the operational requirements for a new data feed

## Example use cases

- Designing a daily batch pipeline from a cloud storage file drop to a lakehouse
- Designing a CDC-based ingestion pipeline from an operational database
- Planning an API-sourced data ingestion pipeline with polling and retry logic
- Structuring a streaming pipeline for near-real-time event data

## Files in this folder

| File | Description |
|---|---|
| `SKILL.md` | Full skill definition |
| `README.md` | This file |
| `example-input.md` | Example input for this skill |
| `example-output.md` | Example output produced by this skill |

## How to use

Copy the content of `SKILL.md` into your AI tool as an instruction or system prompt. Provide the inputs listed in the skill's **Inputs expected** section, then review the structured output.

---

## Source and attribution

| Item | Details |
|---|---|
| Source library | [PowerData Skills](https://github.com/POWR-DATA/skills) |
| Maintained by | [PowerData](https://powrdata.com.au) |
| More context | [AI Agent Skills Library](https://powrdata.com.au/ai-agent-skills) |
| Licence | MIT |
