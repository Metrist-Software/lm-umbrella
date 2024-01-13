import { Hook } from 'phoenix_typed_hook'

export class LogViewer extends Hook {
  private debounceTimeoutId: ReturnType<typeof setTimeout> | undefined;

  mounted() : void {
    // this.el.addEventListener('scroll', this.handleScroll.bind(this))
    this.el.addEventListener('wheel', (event) => {
      // event.preventDefault()
      console.log(event)
      const eventType = event.deltaY > 0 ? 'load_next' : 'load_prev'
      this.pushEvent(eventType, {})
    })
  }

  handleScroll (event) {
    if (this.debounceTimeoutId) clearTimeout(this.debounceTimeoutId)

    this.debounceTimeoutId = setTimeout(() => {
      console.log(this)
      const totalLines = event.target.innerText.split('\n').length

      const bottomPosition = ((event.target.scrollTop + event.target.clientHeight) / event.target.scrollHeight)
      const topPosition = (event.target.scrollTop / event.target.scrollHeight)

      // const topLine = Math.floor(topPosition * totalLines)
      // const bottomLine = Math.ceil(bottomPosition * totalLines) - 1

      // console.log(topLine, bottomLine)

      console.log(this)


      if (topPosition <= 0.1) this.pushEvent('load_prev', {})
      if (bottomPosition >= 0.9) this.pushEvent('load_next', {})


      console.log(topPosition, bottomPosition)
    }, 500)
  }
}
