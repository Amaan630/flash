public class ExploringActivity : RoutineBehavior
{
    public float Duration = 3f;

    public new BehaviorType Type => BehaviorType.Leisure;

    public new PersonalityType[] SuitablePersonalities => new PersonalityType[] {
        PersonalityType.Carefree,
        PersonalityType.Ambitious,
        PersonalityType.Outgoing,
    };

    public new bool CanExecute()
    {
        throw new System.NotImplementedException();
    }

    public new void Execute()
    {
        throw new System.NotImplementedException();
    }

    public new void Interrupt()
    {
        throw new System.NotImplementedException();
    }

    public new void Resume()
    {
        throw new System.NotImplementedException();
    }
}