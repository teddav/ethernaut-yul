module.exports = {
    parser: '@typescript-eslint/parser',
    extends: ['eslint:recommended', 'plugin:@typescript-eslint/recommended', 'prettier'],
    plugins: ['prettier', '@typescript-eslint', 'simple-import-sort'],
    env: {
        node: true,
        mocha: true,
    },

    rules: {
        strict: ['error', 'global'],
        'prettier/prettier': ['error', { tabWidth: 4, useTabs: false }],

        'array-bracket-spacing': ['off'],
        camelcase: ['error', { properties: 'always', allow: ['(.*?)__factory'] }],
        'eol-last': ['error', 'always'],
        'max-len': ['error', 150, 2, { ignoreComments: true }],

        // @typescript-eslint/comma-dangle
        // 'comma-dangle': [
        //     'error',
        //     {
        //         arrays: 'always-multiline',
        //         objects: 'always-multiline',
        //         imports: 'never',
        //         exports: 'never',
        //         functions: 'never'
        //     },
        // ],

        'simple-import-sort/imports': 'error',
        'simple-import-sort/exports': 'error',

        'no-tabs': ['error', { allowIndentationTabs: true }],
        indent: ['error', 4],
    },

    parserOptions: {
        ecmaVersion: 2020,
    },
};
