// @flow
import {createLayout} from '../util/struct_array.js';

import type {StructArrayLayout} from '../util/struct_array.js';

export const boundsGlobeAttributesExt: StructArrayLayout = createLayout([
    {name: 'a_pos_3', components: 3, type: 'Int16'},
]);

export default (createLayout([
    {name: 'a_pos', type: 'Int16', components: 2},
    {name: 'a_texture_pos', type: 'Int16', components: 2}
]): StructArrayLayout);
