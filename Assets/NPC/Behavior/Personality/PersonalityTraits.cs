using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class PersonalityTraits
{
    public static Dictionary<PersonalityType, Dictionary<LeisureActivity, int>> ActivityProbabilities = new Dictionary<PersonalityType, Dictionary<LeisureActivity, int>>
    {
        {
            PersonalityType.Outgoing, new Dictionary<LeisureActivity, int>
            {
                { LeisureActivity.Socializing, 25 },
                { LeisureActivity.Exploring, 15 },
                { LeisureActivity.Relaxing, 10 },
            }
        },
        {
            PersonalityType.Reserved, new Dictionary<LeisureActivity, int>
            {
                { LeisureActivity.Socializing, 5 },
                { LeisureActivity.Exploring, 10 },
                { LeisureActivity.Relaxing, 35 },
            }
        },
        {
            PersonalityType.Ambitious, new Dictionary<LeisureActivity, int>
            {
                { LeisureActivity.Socializing, 30 },
                { LeisureActivity.Exploring, 15 },
                { LeisureActivity.Relaxing, 5 },
            }
        },
        {
            PersonalityType.Carefree, new Dictionary<LeisureActivity, int>
            {
                { LeisureActivity.Socializing, 15 },
                { LeisureActivity.Exploring, 20 },
                { LeisureActivity.Relaxing, 15},
            }
        }
    };
}