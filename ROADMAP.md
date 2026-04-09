# ChoreCalendar iOS - Roadmap

## v1.0 - MVP (current)
- [x] Shopping lists: full-width cards, create/delete lists, color picker
- [x] Shopping items: add with autocomplete, check/uncheck (optimistic), swipe-to-delete, clear checked
- [x] Meals: week view with day cards, recipe picker with 2-step confirm + scaling
- [x] Meal detail: ingredient scaling (ported IngredientFormatter), instructions
- [x] Aggregated weekly ingredients list with "add missing to shopping list"
- [x] App icon from web app favicon
- [x] Xcode project via xcodegen with auto-signing

### Known issues / quick wins
- [ ] Error banner: surface `store.error` to the user (currently silent failures)
- [ ] Loading skeleton states instead of plain ProgressView spinners
- [ ] Handle network unreachable gracefully (show offline banner)
- [ ] Meal day cards: tapping a filled card should navigate to detail (wired but needs testing)
- [ ] JSONDecoder: add `.convertFromSnakeCase` if API ever returns snake_case keys (currently camelCase, but worth a guard)

## v1.1 - Location-aware shopping
- [ ] **Store geofencing**: Save frequently visited stores (name + location) and associate shopping lists with them
- [ ] **Arrival notifications**: When entering a geofenced store, push a local notification with unchecked items from the associated list
- [ ] **Auto-surface list**: Automatically open the relevant shopping list when arriving at a saved store
- [ ] **Nearby store suggestions**: On the weekly ingredients view, show nearby stores based on current location
- [ ] **Commute meal reminder**: Geofence work location; on departure, notify with tonight's meal plan + prep time so you know if you need to stop for ingredients

### Implementation notes
- iOS supports up to 20 monitored `CLCircularRegion`s - plenty for common stores + work
- Use `CLLocationManager.startMonitoring(for:)` - no continuous GPS needed, minimal battery
- Store locations in a local `Stores` model (name, coordinate, associated list ID)
- Notifications via `UNUserNotificationCenter` with list summary in the body
- Need `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` in Info.plist

## v1.2 - Polish
- [ ] Edit shopping list (rename, change color)
- [ ] Reorder items (drag & drop via `onMove`)
- [ ] User picker (multi-user household support - API already has `/api/users`)
- [ ] Offline support with background sync (queue mutations, replay on reconnect)
- [ ] Widget: today's meal plan on home screen (WidgetKit, `IntentTimelineProvider`)
- [ ] Widget: shopping list quick-view (show unchecked count per list)
- [ ] Pull-to-refresh haptic feedback
- [ ] Swipe between weeks on meals tab (gesture-based navigation)
- [ ] Search/filter within a shopping list
- [ ] Duplicate a shopping list (template lists like "weekly staples")

## v2.0 - Deep integration
- [ ] **Siri Shortcuts**: "What's for dinner?", "Add milk to groceries", "Read me the shopping list"
- [ ] **Share sheet**: Add items from Safari/other apps via share extension
- [ ] **Apple Watch**: Shopping list checkoff companion (WatchConnectivity)
- [ ] **Calendar sync**: Meal plan entries in iOS Calendar (EventKit)
- [ ] **Live Activity**: Show current shopping list progress on lock screen while at store
- [ ] **Spotlight**: Index recipes and meal plans for system search
- [ ] **App Intents**: Expose actions for Shortcuts app and Action Button
