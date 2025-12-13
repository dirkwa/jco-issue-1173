// Test the jco-transpiled .NET WASM component
import * as minimal from './jco-output/minimal.js';

console.log('Loading .NET WASM component via jco...');

try {
    // Wait for async initialization
    if (minimal.$init) {
        await minimal.$init;
        console.log('$init completed');
    }

    // This call crashes with: RuntimeError: null function or function signature mismatch
    console.log('Calling plugin.getId()...');
    const id = minimal.plugin.getId();
    console.log('Result:', id);
} catch (err) {
    console.error('Error:', err.message);
    console.error(err.stack);
    process.exit(1);
}
