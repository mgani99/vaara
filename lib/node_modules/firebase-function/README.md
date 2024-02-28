# Firebase Function

Used to manage a backend api with firebase functions by creating a single firebase function for an api functionallity, these functions also handles security be encrypting / decrypting the parameters and return type. Also allows easy, secure and type-save access to the firebase realtime-database.  

## Table of Contents

- [Firebase Function](#firebase-function)
    - [Table of Contents](#table-of-contents)
    - [Create a new Firebase Function](#create-a-new-firebase-function)
    - [Deploy the Functions](#deploy-the-functions)
    - [Function Parameters](#function-parameters)
    - [Return type](#return-type)
    - [Security / Private Keys](#security--private-keys)
    - [Error Handling](#error-handling)
    - [Call your Functions](#call-your-functions)
- [Realtime Database](#realtime-database)
    - [Define a Scheme](#define-a-scheme)
    - [Accessing the Database](#accessing-the-database)
- [Test your Functions](#test-your-functions)
    - [Call your Functions](#call-your-functions-1)
    - [Realtime Database](#realtime-database-1)
    - [Authentication](#authentication)

## Create a new Firebase Function

You can create a new firebase function by declaring a new class that conforms to `FirebaseFunction<MyFunctionType>` interface.

```typescript
import { type FirebaseFunction, type ILogger, ParameterContainer, ParameterParser, type FunctionType } from 'firebase-function';
import { type AuthData } from 'firebase-functions/lib/common/providers/tasks';

export class MyFunction implements FirebaseFunction<MyFunctionType> {
    public readonly parameters: FunctionType.Parameters<MyFunctionType> & { databaseType: DatabaseType };

    public constructor(data: Record<string, unknown> & { databaseType: DatabaseType }, auth: AuthData | undefined, private readonly logger: ILogger) {
        this.logger.log('MyFunction.constructor', { data: data, auth: auth }, 'notice');
        const parameterContainer = new ParameterContainer(data, getPrivateKeys, this.logger.nextIndent);
        const parameterParser = new ParameterParser<FunctionType.Parameters<EventEditFunctionType>>({}, this.logger.nextIndent);
        parameterParser.parseParameters(parameterContainer);
        this.parameters = parameterParser.parameters;
    }

    public async executeFunction(): Promise<FunctionType.ReturnType<MyFunctionType>> {
        this.logger.log('MyFunction.executeFunction', {}, 'info');
        // Do whatever your function should do
    }
}

export type MyFunctionType = FunctionType<Record<string, never>, void>;
```

This is the skeleton of a empty firebase function with no parameters. To add parameters to your firebase function see [Function Parameters](#function-parameters). If you want to return a value back to the frontend, see the [Return type](#return-type) Chapter.

You can get this skeleton via autocompletition in VS-Code, just add the `functions.code-snippets` file to your `.vscode` folder.

## Deploy the Functions

To deploy your firebase functions, add them in a seperate file such that they satisfies the `FirebaseFunctionsType`. **Important**: The `satisties` keyword requiers at least Typescript 4.9.

```typescript
import { FirebaseFunctionDescriptor, type FirebaseFunctionsType } from 'firebase-function';
import { MyFunction, type MyFunctionType } from './MyFunction';
import { MyOtherFunction, type MyOtherFunctionType } from './MyOtherFunction';
import { MyThirdFunction, type MyThirdFunctionType } from './MyThirdFunction';

export const firebaseFunctions = {
    myFunction: FirebaseFunctionDescriptor.create<MyFunctionType>(MyFunction),
    myNamespace: {
        myOtherFunction: FirebaseFunctionDescriptor.create<MyOtherFunctionType>(MyOtherFunction),
        myThirdFunction: FirebaseFunctionDescriptor.create<MyThirdFunctionType>(MyThirdFunction)
    }
} satisfies FirebaseFunctionsType;
```

You can nest multiple functions in a namespace by adding them in a nested object. These functions than have the prefix of the namespace, seperated by a `-`. You can nest functions in as many namespaces as you wish. In this example you deploy three functions with names: `myFunction`, `myNamespace-myOtherFunction` and `myNamespace-myThirdFunction`.

Then in your `index.ts` file you initialize the app and make the firebase functions deployable:

```typescript
import * as admin from 'firebase-admin';
import { createFirebaseFunctions } from 'firebase-function';
import { firebaseFunctions } from './firebaseFunctions';
import { getPrivateKeys } from './privateKeys';

admin.initializeApp();

export = createFirebaseFunctions(firebaseFunctions, getPrivateKeys);
```

Learn more about the private keys and how the functions are secured in [Security / Private Keys](#security-private-keys).

At the end deploy your functions as always by running `firebase deploy --only functions` in your firebase directory.

## Function Parameters

The firebase function can have multiple parameters of different types: 

- `boolean` A boolean value: `true` or `false`.
- `string` Represents textual values like `"Hello, World!"`
- `number` Floating point number or integer value.
- `object` Keyed value pairs.
- `array` List of multiple values.
- `null` The `null` value.
- `undefined` Absent of a value.

You define the parameters as the first type parameter of the `FunctionType`:

```typescript
export type MyFunctionType = FunctionType<{
    name: string;
    gender: 'male' | 'female';
    address: Address;
}, void>;

interface Address {
    city: string;
    street: string;
} 
```

Now you have to implement the `parameterParser` in the function constructor:

```typescript
const parameterParser = new ParameterParser<FunctionType.Parameters<EventEditFunctionType>>({
    name: ParameterBuilder.value('string'),
    gender: ParameterBuilder.guard('string', isValidGender),
    address: ParameterBuilder.build('object', parseAddress)
}, this.logger.nextIndent);


function isValidGender(value: string) value is 'male' | 'female' {
    return value === 'male' || value === 'female';
}

function parseAddress(value: object | null, logger: ILogger): Address {
    logger.log('parseAdress', { value: value });

    if (value === null)
        throw HttpsError('internal', 'Couldn\'t get address from null.', logger);

    if (!('city' in value) || typeof value.city !== 'string')
        throw HttpsError('internal', 'Couldn\'t get city for address.', logger);

    if (!('street' in value) || typeof value.street !== 'string')
        throw HttpsError('internal', 'Couldn\'t get street for address.', logger);

    return {
        city: value.city,
        street: value.street
    };
}
```

You can access the parameters via `this.parameters` property. There are always a `databaseType` parameter which specifies the database type: `release`, `debug` or `testing`.

## Return type

You can specify the return type in the second type parameter of the `FunctionType`:

```typescript
export type MyFunctionType = FunctionType<{
    name: string;
    gender: 'male' | 'female';
    address: Address;
}, string>;
```

## Security / Private Keys

You can check whether an user is signed in that called this function by checking the `auth` parameter passed to the firebase function constructor.

Why are there three database types, that are always part of the parameters? As the values of the database type says, the are different realtime databases for debug and for the tests, so they don't interfere with the actual data of the release database.

The private keys contains three values:

1. `databaseUrl` This is the url to the realtime database.
2. `callSecretKey` This is a key used to identify that the call was made from an authorized frontend.
3. `cryptionKeys` These keys are used to decrypt the parameters and encrypt the return value. Also used to en- / decrypt the data on the database.

It's recommended that for each database different keys are used. That's like an example would look like:

```typescript
export function getPrivateKeys(databaseType: DatabaseType): PrivateKeys {
    switch (databaseType.value) {
        case 'release': return {
            cryptionKeys: {
                encryptionKey: new FixedLength(Uint8Array.from([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f]), 32),
                initialisationVector: new FixedLength(Uint8Array.from([0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f]), 16),
                vernamKey: new FixedLength(Uint8Array.from([0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3b, 0x3c, 0x3d, 0x3e, 0x3f, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4c, 0x4d, 0x4e, 0x4f]), 32)
            },
            callSecretKey: '!^xil&hAGv8&NDFWie$*jrmO!1#8Sf7tt%5a^zx%R6j0cvjkP$TCwxh573$OG6FF',
            databaseUrl: 'https://my-database-release.firebasedatabase.app/'
        };
        case 'debug': return {
            cryptionKeys: {
                encryptionKey: new FixedLength(Uint8Array.from([0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5b, 0x5c, 0x5d, 0x5e, 0x5f, 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f]), 32),
                initialisationVector: new FixedLength(Uint8Array.from([0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f]), 16),
                vernamKey: new FixedLength(Uint8Array.from([0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f, 0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f]), 32)
            },
            callSecretKey: 'NAKM*sQFVI6gIJ48oiKNZpHyoI!hkTT68wcwl2baejhBa!GGHAE$zk5vfF8Ua07G',
            databaseUrl: 'https://my-database-debug.firebasedatabase.app/'
        };
        case 'testing': return {
            cryptionKeys: {
                encryptionKey: new FixedLength(Uint8Array.from([0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf, 0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf]), 32),
                initialisationVector: new FixedLength(Uint8Array.from([0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf]), 16),
                vernamKey: new FixedLength(Uint8Array.from([0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf, 0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef]), 32)
            },
            callSecretKey: 'LI9OxnKdHEuShIS@40%oM2@F2deFzomiaxd7!7TFrFrAIKFFEu&#qoL#ziLj@myo',
            databaseUrl: 'https://my-database-testing.firebasedatabase.app/'
        };
    }
}
```

Make sure to **not** add the private keys to your version control system like `git`.

## Error Handling

Errors are handled as a `HttpsError` which takes a `FunctionsErrorCode` and a message as input. If you throw any other error, your frontend will just receive an `unknown` error code.

## Call your Functions

To call your functions from your frontend, pass this parameters

- `verbose` The verbose level of the logger.
- `databaseType` Database type of the function.
- `callSecret`
    - `expiresAt` Utc date when the call secret expires.
    - `hashedData` Sha512 hashed `expiresAtUtcDate` with call secret key as key.
- `parameters` Encrypted parameters.

and decrypt the return value, like in this example:

```typescript
const crypter = new Crypter(this.cryptionKeys);
const expiresAtUtcDate = UtcDate.now.advanced({ minute: 1 });
const callableFunction = functions.httpsCallable<{
    verbose: VerboseType;
    databaseType: DatabaseType.Value;
    callSecret: CallSecret;
    parameters: string;
}, string>(functionName);
const httpsCallableResult = await callableFunction({
    verbose: 'verbose',
    databaseType: databaseType,
    callSecret: {
        expiresAt: expiresAtUtcDate.encoded,
        hashedData: Crypter.sha512(expiresAtUtcDate.encoded, this.callSecretKey)
    },
    parameters: crypter.encodeEncrypt(parameters)
});
const result = await crypter.decryptDecode(httpsCallableResult.data);        
```

For now it's only possible to call the firebase functions with typescript / javascript and swift as this are the only languages I have implemented the crypter. If you would like to use a different language, feel free to implement the crypter yourself. For that see the crypter in `/src/crypter/Crypter.ts`. 

# Realtime Database

This package allows easy, secure and type-save access to the firebase realtime-database. 

## Define a Scheme

Therefore you need to define a scheme for your database, e.g.:

```typescript
import { type CryptedScheme, type DatabaseSchemeType } from 'firebase-function';

export type DatabaseScheme = DatabaseSchemeType<{
    myValue: string;
    myOtherData: { 
        value1: boolean;
        value2: number | null;
    };
    sensibleData: {
        [UserId in string]: CryptedScheme<User>;
    };
}>;
```

This scheme defines the database as follows:

- In the root of the database there are three values: `myValue`, `myOtherData` and `sensibleData`.
- `myValue` is just a plain string value.
- `myOtherData` is a nested object, that contains a boolean value `value1` and an optional number value `value2`.
- `sensibleData` is a collection of users, keyed by the user ids. As user informations are sensible data, we want to encrypt the data on the database. This can be defined by `CryptedScheme<User>` in the database scheme.

## Accessing the Database

First you need to create a reference to the database:

```typescript
const reference = DatabaseReference.base<DatabaseScheme>(getPrivateKeys(this.parameters.databaseType));
```

With this reference you can `remove` data from the database:

```typescript
await reference.child('sensibleData').child('aUserId').remove();
```

or setting / update the data:

```typescript
await reference.child('myValue').set('this is a value'); // Not crypted data
await reference.child('sensibleData').child('aUserId').set(aUser, 'encrypt'); // Crypted data
```

To check whether there is data at all, check if the snapshot exists:

```typescript
const snapshot = await reference.child('sensibleData').child('aUserId').snapshot();
if (snapshot.exists)
    // Do something with the data
```

and then you can get the value of the snapshot:

```typescript
const snapshot = await reference.child('myOtherData').snapshot();
const myValue1 = snapshot.child('value1').get(); // Not crypted data

const snapshot = await reference.child('sensibleData').child('aUserId').snapshot();
const aUser = snapshot.get('decrypt'); // Crypted data
```

# Test your Functions

First create a firebase app with all the configuration and private keys:

```typescript
import { FirebaseApp } from 'firebase-function/lib/src/testUtils';

export const firebaseApp = new FirebaseApp<typeof firebaseFunctions, DatabaseScheme>(firebaseConfig, cryptionKeys, callSecretKey, {
    name: 'my-database'; // optional
    functionsRegion: 'europe-west1', // optional
    databaseUrl: 'https://my-database-testing.firebasedatabase.app/' // optional
});
```

## Call your Functions

The parameters passed to the function has to be primitive, like a json object. For example if you pass an id with a `Uuid` as parameter, you don't want to pass the `Uuid` object, but just the id as string. For this you need to define this flatten version of parameters as third type parameter of the `FunctionType` in your firebase function definition:

```typescript
export type MyOtherFunctionType = FunctionType<{
    id: Uuid;
}, string, {
    id: string;
}>;
```

Now you can call this function in your tests:

```typescript
const id = new Uuid();
const result = await firebaseApp.functions.function('myNamespcea').function('myOtherFunction').call({
    id: id.rawValue
});
```

You can check if the call succeeds and the return value by get the result value of the function call:

```typescript
result.success.equal('my expected value');
```

Alternative if you expect that your function will throw an error, you can check the result to failure and also the `FunctionsErrorCode` and the message:

```typescript
result.failure.equal({
    code: 'unavailable',
    message: 'Expected message'
});
```

## Realtime Database

To set the initial test data in the database there are convenient methods:

```typescript
await firebaseApp.database.child('myValue').set('this is a value'); // Not crypted data
await firebaseApp.database.child('sensibleData').child('aUserId').set(aUser, 'encrypt'); // Crypted data
await firebaseApp.database.child('sensibleData').child('anotherUserId').remove();
const existsUser = await firebaseApp.database.child('sensibleData').child('aUserId').exists;
const myValue = await firebaseApp.database.child('myValue').get(); // Not crypted data
const aUser = await firebaseApp.database.child('sensibleData').child('aUserId').get('decrypt'); // Crypted data
```

## Authentication

If you need an user to be signed in while calling the functions, you can use:

```typescript
await firebaseApp.auth.signIn(user.email, user.password);
await firebaseApp.auth.signOut();
```
