# Usage Patterns

This page describes how to use skills from this library across common AI tools.

---

## General approach

Each skill is defined in a `SKILL.md` file. To use a skill:

1. Open the `SKILL.md` for the skill you want.
2. Copy the full content.
3. Paste it into your AI tool as system instructions, a role definition, or a custom agent prompt.
4. Provide the inputs described in the skill's **Inputs expected** section.
5. Review the structured output.

---

## Using skills in Claude Code

You can use skills directly in Claude Code:

- Copy the `SKILL.md` content and paste it into a conversation with a clear instruction such as: "Apply the Use Case to Data Requirements skill to the following use case: [your input]."
- Or reference the `SKILL.md` file directly as context using the `/` file reference and instruct the AI to apply it.

---

## Using skills with GitHub Copilot

Skills can be adapted into Copilot prompt files:

- Place the skill content in a `.github/prompts/` file in your repository.
- Reference it as a reusable instruction in Copilot Chat.
- Adjust the format if needed to match Copilot's expected prompt structure.

---

## Using skills in Cursor or similar tools

- Paste the skill content into a custom agent instruction or system prompt.
- Skills work well as agent instructions in tools that support persistent context or project rules files.

---

## Creating private team versions

Public skills in this repository are intentionally generic. You can extend them privately by:

- Forking or copying the skill into a private repository.
- Adding organisation-specific context such as naming conventions, platform standards, governance requirements, security rules, and architectural constraints.
- Treating the public skill as the baseline and the private extension as the overlay.

This approach lets teams benefit from shared patterns while keeping sensitive details private.

---

## Versioning and review

Because skills are stored as Markdown in a Git repository, they can be:

- Reviewed via pull requests.
- Versioned alongside the code they support.
- Compared over time to track how delivery approaches evolve.

This makes skills more trustworthy than prompts saved in personal notes or chat history.

---

## What skills are not

- Skills are not magic prompts that guarantee correct output.
- Skills are not a replacement for domain knowledge or project-specific context.
- Skills are not standalone. The user still needs to review and validate the AI output.

Skills reduce the activation energy for structured, repeatable AI-assisted delivery. They do not replace engineering judgement.
