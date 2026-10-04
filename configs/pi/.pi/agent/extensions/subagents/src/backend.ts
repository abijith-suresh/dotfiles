import { Context, type Effect, type Scope, type Stream } from "effect";
import type {
  SpawnError,
  SpawnTask,
  SubagentEvent,
  SubagentMeta,
} from "./domain.ts";

export interface SubagentSession {
  readonly meta: Effect.Effect<SubagentMeta>;
  readonly events: Stream.Stream<SubagentEvent>;
  /** Wait for the SDK to acknowledge interruption. The manager enforces a deadline. */
  readonly interrupt: Effect.Effect<void>;
}

export type SpawnSession = (
  task: SpawnTask,
) => Effect.Effect<SubagentSession, SpawnError, Scope.Scope>;

export class SubagentSpawner extends Context.Service<
  SubagentSpawner,
  SpawnSession
>()("subagents/SubagentSpawner") {}
