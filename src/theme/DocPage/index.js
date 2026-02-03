import React from 'react';
import DocPage from '@theme-original/DocPage';
import DocPageWithSearch from '@components/DocPageWithSearch';

export default function DocPageWrapper(props) {
  return (
    <DocPageWithSearch>
      <DocPage {...props} />
    </DocPageWithSearch>
  );
}
