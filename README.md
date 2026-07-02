### Architecture & State Management
- **Folder Organization**: Feature-first structure. Subfolders: `service/`, `cubit/`, `screen/`, `widget/`
- **State Management**: Cubit (not full Bloc) — no events, just methods. Use Cubit for **all** state and logic.
- **Model/State Equality**: Use `Equatable` for value equality on models and states.
- **Reactivity**: App must be fully reactive to state changes. Every data change reflects in the UI immediately.
- **Optimistic Updates**: Implement optimistic UI changes where beneficial to improve perceived performance.
- **Data Streaming**: Use Firebase Streams for real-time data sync when appropriate.

### Development Standards
- **Simplicity**: Keep logic as simple as possible.
- **Clean Code**: Strict separation of concerns.
- **DRY**: Reuse existing functions. Minimize boilerplate. No speculative or "future-proof" code.
- **Logging**: Catch and use `debugPrint` for errors at any level and for success of major operations. Show UI feedback to users **only on error**, never on success.
- **Logging Format**: All `debugPrint` statements must include a class tag for filtering — e.g., `[AlarmService]`, `[AlarmCubit]`.
- **Comments**: Use comments to succinctly explain functions, objects, and steps.
