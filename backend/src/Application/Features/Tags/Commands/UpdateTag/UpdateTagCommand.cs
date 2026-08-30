using FluentValidation;
using MediatR;
using AutoMapper;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Tags.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Application.Features.Tags.Commands.UpdateTag;

public record UpdateTagCommand(Guid Id, UpdateTagRequestDto Request) : IRequest<TagDto>;

public class UpdateTagCommandValidator : AbstractValidator<UpdateTagCommand>
{
    public UpdateTagCommandValidator()
    {
        RuleFor(v => v.Id).NotEmpty().WithMessage("Tag Id is required.");
        RuleFor(v => v.Request.Name).NotEmpty().WithMessage("Tag name is required.");
    }
}

public class UpdateTagCommandHandler : IRequestHandler<UpdateTagCommand, TagDto>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IMapper _mapper;

    public UpdateTagCommandHandler(
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _mapper = mapper;
    }

    public async Task<TagDto> Handle(UpdateTagCommand request, CancellationToken cancellationToken)
    {
        var userId = _currentUserService.UserId ?? throw new UnauthorizedException();
        var tag = await _unitOfWork.Tags.GetByIdAsync(request.Id, cancellationToken);

        if (tag == null || (tag.UserId != null && tag.UserId != userId))
        {
            throw new NotFoundException(nameof(Tag), request.Id);
        }

        tag.Name = request.Request.Name.Trim().ToLowerInvariant();
        tag.UpdatedDate = DateTime.UtcNow;

        _unitOfWork.Tags.Update(tag);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return _mapper.Map<TagDto>(tag);
    }
}
