import { Hook } from 'phoenix_typed_hook'
import vegaEmbed, { Result, vega } from 'vega-embed'

export class VegaLite extends Hook {
  id: string
  vegaResult: Result | null

  mounted() : void {
    this.id = this.el.getAttribute('data-id') ?? ''

    this.handleEvent(`vega_lite:${this.id}:init`, async ({spec}) => {
      this.vegaResult = await vegaEmbed(this.el, spec, {
        actions: false
      })
    })

    // Inserts a new piece of telemetry
    this.handleEvent(`vega_lite:${this.id}:add_telem`, async (data) => {
      if (!this.vegaResult) return
      const changeset = vega.changeset().insert([data])

      this.vegaResult.view.change('chart', changeset).run()
    })

    // Replaces all existing telemetry with the given telemetry
    this.handleEvent(`vega_lite:${this.id}:replace_telem`, async (data) => {
      if (!this.vegaResult) return

      const changeset = vega.changeset()
        .remove((t) => true)
        .insert([data])

      this.vegaResult.view.change('chart', changeset).run()
    })

    // Swaps existing telemetry that has the same tags
    this.handleEvent(`vega_lite:${this.id}:swap_telem`, async (data) => {
      if (!this.vegaResult) return

      const changeset = vega.changeset()
        .remove((t) => t.tags == data.tags)
        .insert([data])

      this.vegaResult.view.change('chart', changeset).run()
    })

  }

  destroyed(): void {
    this.vegaResult?.view.finalize()
  }
}
