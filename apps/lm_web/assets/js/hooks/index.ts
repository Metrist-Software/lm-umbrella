
import { makeHook } from 'phoenix_typed_hook'
import * as VegaLiteHooks from './vegalite'
import * as LogViewerHooks from './logViewer'
import * as HelperHooks from './helpers'
import LiveReact from 'phoenix_live_react'

const allTypedHooks = {
  ...VegaLiteHooks,
  ...LogViewerHooks,
  ...HelperHooks
}

let hooks = Object.fromEntries(
  Object.entries(allTypedHooks)
  .map(([key, val]) => [key, makeHook(val)])
)

hooks = {
  ...hooks,
  LiveReact
}

export default hooks

