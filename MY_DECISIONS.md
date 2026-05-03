#  <#Title#>

#  <#Title#>

## Decisions
1. Use local SPM pacakge to share code between app target and app clip, so functionality can be easily extended to app. Requirement only called for an App Clip. Given the purpose of App Clips being a springboard into a full blown app experience, I chose to go with a local SPM package so functionality can easily be extended to app if needed.
2. Cart Persistence: In-memory only. This is acceptable given the ephemeral nature of an App Clip
3. For description property, go with `descriptionHtml` + `NSAttributedString` to format description text.
4. Program to protocols, not concrete implementations. 
5. Use ScreenFactory to isolate dependencies from parents/creators

## AI Usage
- Planning: Translating product requirements into technical specification
- Brainstorming options and surfacing drawbacks
