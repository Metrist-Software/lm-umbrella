import React from 'react';
import GridLayout from 'react-grid-layout'
import { VegaLite } from 'react-vega'

export class MyComponent extends React.Component {
  render() {
    const specNames = Object.keys(this.props.specs)

    const spec0 = this.props.specs[specNames[0]]

    // layout is an array of objects, see the demo for more complete usage
    const layout = [
      { i: specNames[0], x: 0, y: 0, w: 10, h: 8, },
      { i: specNames[1], x: 1, y: 0, w: 3, h: 2, minW: 2, maxW: 4 },
      { i: specNames[2], x: 4, y: 0, w: 1, h: 2 }
    ];
    return (
      <div class="bg-red-300">
        <GridLayout
          className="layout"
          layout={layout}
          cols={12}
          rowHeight={30}
          width={1200}
          >
          <div key={specNames[0]}>
            {/* <div class="bg-gray-600 h-full">a</div> */}

            <VegaLite spec={spec0}/>
          </div>
          <div key={specNames[1]}>
            <div class="bg-gray-600 h-full">b</div>
          </div>
          <div key={specNames[2]}>
          <div class="bg-gray-600 h-full">c</div>
          </div>
        </GridLayout>
      </div>
    );
  }
}

