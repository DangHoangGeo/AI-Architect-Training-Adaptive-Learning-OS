# Appendix C — AI Application Checklist (if the system includes LLMs/ML)

- [ ] Treat all model input containing user/third-party content as untrusted → prompt-injection mitigations (instruction/data separation, tool allow-lists, output constraints).
- [ ] Treat model output as untrusted input: validate/encode before executing, rendering, or passing to tools.
- [ ] RAG authorization at retrieval time: users can only retrieve documents they're entitled to see (filter in the vector store query, not after generation).
- [ ] No sensitive data sent to model APIs without an approved data agreement; redact/mask where possible.
- [ ] Cost controls: per-user token quotas, max tokens per request, monthly budget alarms, caching of repeated prompts.
- [ ] Model failure plan: timeout, fallback model or degraded non-AI path, user-visible messaging.
- [ ] Evaluation set exists: golden Q&A pairs run on every prompt/model change (regression testing for AI).
- [ ] Human feedback loop: users can flag bad outputs; flags are reviewed.
- [ ] Logging of prompts/outputs follows the same PII rules as everything else, with clear retention.