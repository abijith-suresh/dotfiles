/** Results stay retractable until an explicit collector succeeds. */
export function createDeferredResultDelivery<T extends { id: string }>() {
  const pending = new Map<string, T>();
  const holds = new Map<string, number>();
  const consumed = new Set<string>();

  return {
    defer(result: T) {
      if (!consumed.has(result.id)) pending.set(result.id, result);
    },
    hold(ids: Iterable<string>) {
      const unique = [...new Set(ids)];
      for (const id of unique) holds.set(id, (holds.get(id) ?? 0) + 1);
      let released = false;
      return () => {
        if (released) return;
        released = true;
        for (const id of unique) {
          const count = (holds.get(id) ?? 1) - 1;
          if (count === 0) holds.delete(id);
          else holds.set(id, count);
        }
      };
    },
    consume(ids: Iterable<string>) {
      for (const id of ids) {
        pending.delete(id);
        consumed.add(id);
      }
    },
    drain() {
      const results: T[] = [];
      for (const [id, result] of pending) {
        if (holds.has(id)) continue;
        results.push(result);
        pending.delete(id);
        consumed.add(id);
      }
      return results;
    },
    clear() {
      pending.clear();
      holds.clear();
      consumed.clear();
    },
  };
}
