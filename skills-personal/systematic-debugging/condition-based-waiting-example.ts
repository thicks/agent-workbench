// Condition-based waiting: one primitive, thin helpers.
//
// Polling is the portable choice when the producer has no subscribe API.
// If ThreadManager (or equivalent) can emit events, prefer a listener and
// keep this poller for tests that can only snapshot state.
//
// The deadline is checked after each probe. Worst-case wait is
// timeoutMs + POLL_INTERVAL_MS.

const POLL_INTERVAL_MS = 10;
const DEFAULT_TIMEOUT_MS = 5_000;

export type Probe<T> = () => T | undefined;

export function waitFor<T>(
  probe: Probe<T>,
  describe: string,
  timeoutMs = DEFAULT_TIMEOUT_MS,
): Promise<T> {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    let timer: ReturnType<typeof setTimeout> | undefined;

    const finish = (fn: () => void) => {
      if (timer !== undefined) clearTimeout(timer);
      fn();
    };

    const check = () => {
      const value = probe();
      if (value !== undefined) {
        finish(() => resolve(value));
        return;
      }
      if (Date.now() - start > timeoutMs) {
        finish(() =>
          reject(new Error(`Timeout waiting for ${describe} after ${timeoutMs}ms`)),
        );
        return;
      }
      timer = setTimeout(check, POLL_INTERVAL_MS);
    };

    check();
  });
}

/** Minimal stand-in so this file typechecks without a private path alias. */
export type ThreadEvent = { type: string; data?: unknown };
export type ThreadSnapshot = { getEvents: (threadId: string) => ThreadEvent[] };

export const waitForEvent = (
  tm: ThreadSnapshot,
  id: string,
  type: string,
  timeoutMs = DEFAULT_TIMEOUT_MS,
): Promise<ThreadEvent> =>
  waitFor(
    () => tm.getEvents(id).find((e) => e.type === type),
    `${type} event`,
    timeoutMs,
  );

export const waitForEventCount = (
  tm: ThreadSnapshot,
  id: string,
  type: string,
  count: number,
  timeoutMs = DEFAULT_TIMEOUT_MS,
): Promise<ThreadEvent[]> =>
  waitFor(
    () => {
      const matching = tm.getEvents(id).filter((e) => e.type === type);
      return matching.length >= count ? matching : undefined;
    },
    `${count} ${type} events`,
    timeoutMs,
  );

export const waitForEventMatch = (
  tm: ThreadSnapshot,
  id: string,
  predicate: (event: ThreadEvent) => boolean,
  description: string,
  timeoutMs = DEFAULT_TIMEOUT_MS,
): Promise<ThreadEvent> =>
  waitFor(
    () => tm.getEvents(id).find(predicate),
    description,
    timeoutMs,
  );
