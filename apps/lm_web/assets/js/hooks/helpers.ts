import { Hook } from 'phoenix_typed_hook'

export class SizeListener extends Hook {
  private debounceTimeout: ReturnType<typeof setTimeout> | undefined

  mounted() : void {
    this.pushEventTo(this.el.dataset.target || this.el, "element_resized", {id: this.el.id, width: this.el.clientWidth, height: this.el.clientHeight})

    new ResizeObserver(this.handleResize.bind(this)).observe(this.el)
  }

  handleResize() {
    if (this.debounceTimeout) clearTimeout(this.debounceTimeout)

    this.debounceTimeout = setTimeout(() => {
      this.pushEventTo(this.el.dataset.target || this.el, "element_resized", {id: this.el.id, width: this.el.clientWidth, height: this.el.clientHeight})
    }, 100)
  }
}

export class CopyToClipboard extends Hook {
  mounted() : void {
    this.el.addEventListener('click', e => {

      const target = document.getElementById(this.el.dataset.target || '');

      if ("clipboard" in navigator && target?.textContent) {
        navigator.clipboard.writeText(target?.textContent)
      } else {
        alert("Sorry, your browser does not support clipboard copy.")
      }
    })
  }
}
