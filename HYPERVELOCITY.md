# The hypervelocity manifesto

Hypervelocity is the rapid development of software that can be achieved by creating a closed-loop environment where all commands, tests, and logs are available on the CLI. Hypervelocity unleashes agentic software development (and also makes the coding environment really nice for humans too).

## The 300-commit breakthrough

For two weeks in late 2025, I ran an experiment: give an LLM agent complete control over a development environment -- source code, tests, build scripts, terminal access, everything -- and let it iterate autonomously against a real codebase.

The result was 300 commits in two weeks. Not 300 trivial formatting changes—actual functional work, each commit passing the test suite before the next iteration began. And these were commits made while I was on vacation with my family, mostly supervised while my toddler was napping and for an hour or two every evening.

The setup was simple in principle: the agent could run any command, see all output, and make any change. When tests failed, it saw the failure. When logs showed unexpected behavior, it saw those too. It operated in a closed loop -- change, observe, correct, repeat -- without waiting for me to interpret results or approve next steps.

What surprised me was how consistent the results were. When the LLM could test and observe its own output, the quality stopped varying. It didn't matter if I was watching or not, didn't matter if it was the first attempt or the fifteenth. The closed loop produced reliable results—and they were better than the best thoughts Opus gave me when I was actively collaborating with it. The loop was outperforming the conversation.

Three observations from watching this unfold:
**The model mattered less than I expected**. I started with Claude Opus, then switched to less capable models. The clock time that the LLMs took varied, but the overall velocity stayed the same. What kept them productive was that they never stopped. Every failure became immediate input to the next attempt, which converged by the time I looked at the results.
**I had to stay out of the way**. My instinct was to jump in and fix problems when I saw the agent struggling. I had to fight this urge and get the feedback wired up instead. Once I did, agent learned faster from its own failures than from my corrections.
**The constraint was verification, not intelligence**. When the specs and test suite were present, velocity was good. When they were strong, things really took off. The parts of the system that weren't closed-loop -- like deployment -- got left in the dust. The ceiling wasn't the model's capability. It was whether the system could tell the model it was wrong.

## Hypervelocity principles

### Closed-loop development always wins
Software systems that continuously execute, measure, and correct themselves through automated feedback loops will always outpace open-loop development. All codebases must be driven toward closed-loop operation to achieve sustained velocity.

### Self-directed iteration
A development agent must be able to complete the full iteration cycle -- change, observe, correct -- without waiting for human handoffs. This means access to edit code, run services, run tests, and any other tools (whatever is in the loop).

## Total machine observability
A development agent must observe all consequences of its actions: test results, logs, metrics, and runtime behavior. It must access them in a way that make it straightforward to find the errors.

## Verification defines correctness
Correctness is defined by automated verification: tests, checks, and even abstract written tests that can be evaluated autonomously by an agent. Anything covered by a test will be driven to convergence. Anything untested is left to chance.

## What it looks like in practice

### Ideas evolve under feedback
In a closed-loop system, not only code but the very understanding of the problem and architecture evolves as a natural consequence of continuous feedback.

### Legacy is a loop problem, not a model problem
Legacy code fails because it is open-loop. Closing the loop is what unlocks velocity, not replacing the model.

### The CLI is everything
Shell scripts rule the roost. CLI/stdin/stdout is the native language of the LLM and so creating scripts that automate tasks is both agent-friendly and developer-friendly.

### Humans must enforce closure
Humans must resist the urge to fix point issues and must demand systemic, automated solutions.

### Model quality is secondary
A mediocre model in a closed loop outperforms a strong model without feedback. Feedback is more important than initial intelligence.
