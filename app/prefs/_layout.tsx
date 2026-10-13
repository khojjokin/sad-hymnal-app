import React from 'react';
import { Stack } from 'expo-router';
import { C } from '../../src/lib/theme';

export default function PrefsLayout() {
  return <Stack screenOptions={{ headerShown: false, contentStyle: { backgroundColor: C.bg }, animation: 'slide_from_right' }} />;
}
