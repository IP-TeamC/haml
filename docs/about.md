---
layout: page
---

<script setup>
import {
  VPTeamPage,
  VPTeamPageTitle,
  VPTeamMembers
} from 'vitepress/theme'

const members = [
    {
        avatar: 'https://github.com/ltheinrich.png',
        name: 'Lennart Heinrich',
        title: 'ltheinrich',
        links: [
            { icon: 'github', link: 'https://github.com/ltheinrich' }
        ]
    },
        {
        avatar: 'https://github.com/Laubfrosch49.png',
        name: 'Piet Ostendorp',
        title: 'Laubfrosch49',
        links: [
            { icon: 'github', link: 'https://github.com/laubfrosch49' }
        ]
    },
    {
        avatar: 'https://github.com/Marcel-Anker.png',
        name: 'Marcel Anker',
        title: 'Marcel-Anker',
        links: [
            { icon: 'github', link: 'https://github.com/Marcel-Anker' }
        ]
    }
]
</script>

<VPTeamPage>
  <VPTeamPageTitle>
    <template #title>Team C</template>
    <template #lead>
        Projekt entwickelt im Zuge eines Integrationsprojekts an der Fachhochschule für die Wirtschaft Hannover (FHDW)
    </template>
  </VPTeamPageTitle>
  <VPTeamMembers :members />
  <VPTeamPageSection>
    <template #title>Partners</template>
    <template #lead>...</template>
    <template #members>
    </template>
  </VPTeamPageSection>
</VPTeamPage>